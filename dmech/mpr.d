/*
Copyright (c) 2013 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dmech.mpr;

import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.math.utils;

import dmech.geometry;
import dmech.contact;

/*
 * Implementation of the Minkowski Portal Refinement algorithm
 */

void supportTransformed(Geometry s, Vector3f dir, out Vector3f result)
{
    Matrix4x4f m = s.transformation;

    result.x = ((dir.x * m.a11) + (dir.y * m.a12)) + (dir.z * m.a13);
    result.y = ((dir.x * m.a21) + (dir.y * m.a22)) + (dir.z * m.a23);
    result.z = ((dir.x * m.a31) + (dir.y * m.a32)) + (dir.z * m.a33);

    result = s.supportPoint(result);

    float x = ((result.x * m.a11) + (result.y * m.a21)) + (result.z * m.a31);
    float y = ((result.x * m.a12) + (result.y * m.a22)) + (result.z * m.a32);
    float z = ((result.x * m.a13) + (result.y * m.a23)) + (result.z * m.a33);

    result.x = m.a41 + x;
    result.y = m.a42 + y;
    result.z = m.a43 + z;
}

/*
 * TODO:
 * - write c.fact here
 */

bool MPRCollisionTest(
    Geometry s1, 
    Geometry s2,
    ref Contact c)
{
    enum float collideEpsilon = 1e-4f;
    enum maxIterations = 20;
    
    // Used variables
    Vector3f temp1;
    Vector3f v01, v02, v0;
    Vector3f v11, v12, v1;
    Vector3f v21, v22, v2;
    Vector3f v31, v32, v3;
    Vector3f v41, v42, v4;

    Matrix4x4f transform1 = s1.transformation;
    Matrix4x4f transform2 = s2.transformation;
        
    // Initialization of the output
    c.point = c.normal = Vector3f(0.0f, 0.0f, 0.0f);
    c.penetration = 0.0f;

    // Get the center of shape1 in world coordinates
    v01 = transform1.translation;
        
    // Get the center of shape2 in world coordinates
    v02 = transform2.translation;
        
    // v0 is the center of the Minkowski difference
    v0 = v02 - v01;
        
    // Avoid case where centers overlap - any direction is fine in this case
    if (v0.isAlmostZero) 
        v0 = Vector3f(0.00001f, 0.0f, 0.0f);
            
    // v1 = support in direction of origin
    c.normal = -v0;
        
    supportTransformed(s1, v0, v11);
    supportTransformed(s2, c.normal, v12);
    v1 = v12 - v11;
        
    if (dot(v1, c.normal) <= 0.0f)
        return false;
            
    // v2 = support perpendicular to v1,v0
    c.normal = cross(v1, v0);
        
    if (c.normal.isAlmostZero)
    {
        c.normal = v1 - v0;
        c.normal.normalize();

        c.point = v11;
        c.point += v12;
        c.point *= 0.5f;

        c.penetration = dot(v12 - v11, c.normal);

        return true;
    }
        
    supportTransformed(s1, -c.normal, v21);
    supportTransformed(s2,  c.normal, v22);        
    v2 = v22 - v21;

    if (dot(v2, c.normal) <= 0.0f)
        return false;
            
    // Determine whether origin is on + or - side of plane (v1,v0,v2)
    c.normal = cross(v1 - v0, v2 - v0);
        
    float dist = dot(c.normal, v0);
        
    // If the origin is on the - side of the plane, reverse the direction of the plane
    if (dist > 0.0f)
    {
        swap(&v1, &v2);
        swap(&v11, &v21);
        swap(&v12, &v22);
        c.normal = -c.normal;
    }
        
    int phase2 = 0;
    int phase1 = 0;
    bool hit = false;
        
    // Phase One: Identify a portal
    while (true)
    {
        if (phase1 > maxIterations)
            return false;

        phase1++;

        // Obtain the support point in a direction perpendicular to the existing plane
        // Note: This point is guaranteed to lie off the plane
        supportTransformed(s1, -c.normal, v31);
        supportTransformed(s2,  c.normal, v32);
        v3 = v32 - v31;
            
        if (dot(v3, c.normal) <= 0.0f)
            return false;
     
        // If origin is outside (v1,v0,v3), then eliminate v2 and loop
        temp1 = cross(v1, v3);
        if (dot(temp1, v0) < 0.0f)
        {
            v2 = v3;
            v21 = v31;
            v22 = v32;
            c.normal = cross(v1 - v0, v3 - v0);
            continue;
        }
            
        // If origin is outside (v3,v0,v2), then eliminate v1 and loop
        temp1 = cross(v3, v2);
        if (dot(temp1, v0) < 0.0f)
        {
            v1 = v3;
            v11 = v31;
            v12 = v32;
            c.normal = cross(v3 - v0, v2 - v0);
            continue;
        }
            
        // Phase Two: Refine the portal
        // We are now inside of a wedge...
        while (true)
        {
            phase2++;
                
            // Compute normal of the wedge face
            c.normal = cross(v2 - v1, v3 - v1);
                
            // Can this happen? Can it be handled more cleanly?
            if (c.normal.isAlmostZero)
                return true;
                    
            c.normal.normalize();
                
            // Compute distance from origin to wedge face
            float d = dot(c.normal, v1);
                
            // If the origin is inside the wedge, we have a hit
            if (d >= 0 && !hit)
                hit = true;
                
            // Find the support point in the direction of the wedge face
            supportTransformed(s1, -c.normal, v41);
            supportTransformed(s2,  c.normal, v42);
            v4 = v42 - v41;

            float delta = dot(v4 - v3, c.normal);
            c.penetration = dot(v4, c.normal);
                
            // If the boundary is thin enough or the origin is outside 
            // the support plane for the newly discovered vertex, then we can terminate
            if (delta <= collideEpsilon || c.penetration <= 0.0f || phase2 > maxIterations)
            {
                if (hit)
                {
                    float b0 = dot(cross(v1, v2), v3);
                    float b1 = dot(cross(v3, v2), v0);
                    float b2 = dot(cross(v0, v1), v3);
                    float b3 = dot(cross(v2, v1), v0);
                        
                    float sum = b0 + b1 + b2 + b3;
                        
                    if (sum <= 0)
                    {
                        b0 = 0;
                        b1 = dot(cross(v2, v3), c.normal);
                        b2 = dot(cross(v3, v1), c.normal);
                        b3 = dot(cross(v1, v2), c.normal);

                        sum = b1 + b2 + b3;
                    }
                        
                    float inv = 1.0f / sum;
                     
                    c.point = v01 * b0;
                    c.point += v11 * b1;
                    c.point += v21 * b2;
                    c.point += v31 * b3;
                        
                    c.point += v02 * b0;
                    c.point += v12 * b1;
                    c.point += v22 * b2;
                    c.point += v32 * b3;
                       
                    c.point *= inv * 0.5f;
                }
                   
                return hit;
            }
                
            // Compute the tetrahedron dividing face (v4,v0,v3)
            temp1 = cross(v4, v0);
            float d2 = dot(temp1, v1);
                
            if (d2 >= 0.0f)
            {
                d2 = dot(temp1, v2);
                if (d2 >= 0.0f)
                {
                    // Inside d1 & inside d2 ==> eliminate v1
                    v1 = v4;
                    v11 = v41;
                    v12 = v42;
                }
                else
                {
                    // Inside d1 & outside d2 ==> eliminate v3
                    v3 = v4;
                    v31 = v41;
                    v32 = v42;
                }
            }
            else
            {
                d2 = dot(temp1, v3);

                if (d2 >= 0.0f)
                {
                    // Outside d1 & inside d3 ==> eliminate v2
                    v2 = v4;
                    v21 = v41;
                    v22 = v42;
                }
                else
                {
                    // Outside d1 & outside d3 ==> eliminate v1
                    v1 = v4;
                    v11 = v41;
                    v12 = v42;
                }
            }
        }
    }
    
    // Should never get here
    return false;
}

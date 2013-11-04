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

module dmech.rigidbody;

import std.math;

import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.affine;
import dlib.math.quaternion;
import dlib.math.utils;

import dmech.geometry;

/*
 * Absolute rigid body class
 */

class RigidBody
{
    Vector3f position;
    Quaternionf orientation;
    
    float damping;
    float mass;
    float invMass;
    
    float inertiaMoment;
    float invInertiaMoment;
    
    Vector3f linearVelocity;
    Vector3f angularVelocity;
    
    Vector3f pseudoLinearVelocity;
    Vector3f pseudoAngularVelocity;
    
    Vector3f linearAcceleration;
    Vector3f angularAcceleration;
    
    Vector3f forceAccumulator;
    Vector3f torqueAccumulator;

    float bounce;
    float friction;

    Geometry geometry;

    bool dynamic;

    uint id;

    enum VelocityThreshold = 0.04f;
    
    this()
    {
        position = Vector3f(0.0f, 0.0f, 0.0f);
        orientation = Quaternionf(0.0f, 0.0f, 0.0f, 1.0f);
    
        damping = 0.5f;
    
        mass = 1.0f;
        invMass = 1.0f;
    
        inertiaMoment = 1.0f;
        invInertiaMoment = 1.0f;
    
        linearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        angularVelocity = Vector3f(0.0f, 0.0f, 0.0f);
    
        pseudoLinearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        pseudoAngularVelocity = Vector3f(0.0f, 0.0f, 0.0f);
    
        linearAcceleration = Vector3f(0.0f, 0.0f, 0.0f);
        angularAcceleration = Vector3f(0.0f, 0.0f, 0.0f);
    
        forceAccumulator = Vector3f(0.0f, 0.0f, 0.0f);
        torqueAccumulator = Vector3f(0.0f, 0.0f, 0.0f);

        friction = 0.9f;
        bounce = 0.5f;

        geometry = null;

        dynamic = true;

        id = 0;
    }
    
    void integrateForces(float dt)
    {
        if (!dynamic)
            return;
            
        linearAcceleration = forceAccumulator * invMass;
        angularAcceleration = torqueAccumulator * invInertiaMoment;
        
        linearVelocity += linearAcceleration * dt;
        angularVelocity += angularAcceleration * dt;
    }
    
    void integrateVelocities(float dt)
    {
        if (!dynamic)
            return;

        linearVelocity *= clamp(1.0f - dt * damping, 0.0f, 1.0f);
        angularVelocity *= clamp(1.0f - dt * damping, 0.0f, 1.0f);
        
        if (linearVelocity.length < VelocityThreshold)
            linearVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        if (angularVelocity.length < VelocityThreshold)
            angularVelocity = Vector3f(0.0f, 0.0f, 0.0f);
        
        position += linearVelocity * dt;
        orientation += 0.5f * Quaternionf(angularVelocity, 0.0f) * orientation * dt;
        orientation.normalize();
    }

    void resetForces()
    {
        forceAccumulator = Vector3f(0.0f, 0.0f, 0.0f);
        torqueAccumulator = Vector3f(0.0f, 0.0f, 0.0f);
    }

    void setGeometry(Geometry geom)
    {
        geometry = geom;
        updateGeometryTransformation();
    }

    void updateGeometryTransformation()
    {
        if (geometry !is null)
            geometry.transformation = transformation();
    }
    
    void applyForce(Vector3f force)
    {
        if (!dynamic)
            return;

        forceAccumulator += force;
    }
   
    void applyTorque(Vector3f torque)
    {
        if (!dynamic)
            return;

        torqueAccumulator += torque;
    }
    
    void applyImpulse(Vector3f impulse, Vector3f point)
    {
        if (!dynamic)
            return;

        linearVelocity += impulse * invMass;
        Vector3f angularImpulse = cross(point - position, impulse);
        angularVelocity += angularImpulse * invInertiaMoment;
    }
    
    Matrix4x4f transformation()
    {
        Matrix4x4f t;
        t = translationMatrix(position);
        t *= orientation.toMatrix4x4();
        return t;
    }
}

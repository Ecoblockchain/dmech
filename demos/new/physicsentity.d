module physicsentity;

import dlib;
import dgl;
import dmech;

class PhysicsEntity: Entity
{
    ShapeComponent shape;
    bool highlight = false;
    
    this(Drawable d, ShapeComponent s)
    {
        if (s)
            super(d, s.position);
        else
            super(d, Vector3f(0, 0, 0));
        shape = s;
    }
    
    override void draw(double dt)
    {
        if (shape !is null)
            transformation = shape.transformation;
        else
            transformation = Matrix4x4f.identity;
        super.draw(dt);
    }
    
    override void drawModel(double dt)
    {
        super.drawModel(dt);
    }
    
    override void free()
    {
        Delete(this);
    }
}
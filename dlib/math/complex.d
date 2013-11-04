﻿/*
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

module dlib.math.complex;

private
{
    import std.math;
    import std.range;
    import std.format;
}

struct Complex(T)
{
    T re;
    T im;
    
    this(T r, T i)
    {
        re = r;
        im = i; 
    }
    
    this(T r)
    {
        re = r;
        im = 0.0; 
    }
    
    Complex!(T) opUnary(string s) () if (s == "-")
    {
        return Complex!(T)(re, -im);
    }
    
    Complex!(T) opAdd(Complex!(T) c)
    {
        return Complex!(T)(re + c.re, im + c.im);
    }
    
    Complex!(T) opSub(Complex!(T) c)
    {
        return Complex!(T)(re - c.re, im - c.im);
    }
    
    Complex!(T) opMul(Complex!(T) c)
    {
        return Complex!(T)(
            re * c.re - im * c.im, 
            re * c.im + im * c.re);
    }
    
    Complex!(T) opDiv(Complex!(T) c)
    {
        T denominator = c.re * c.re + c.im * c.im;
        return Complex!(T)(
            (re * c.re + im * c.im) / denominator,
            (im * c.re - re * c.im) / denominator);
    }
    
    Complex!(T) opAddAssign(Complex!(T) c)
    {
        re += c.re;
        im += c.im;
        return this;
    }
    
    Complex!(T) opSubAssign(Complex!(T) c)
    {
        re -= c.re;
        im -= c.im;
        return this;
    }
    
    Complex!(T) opMulAssign(Complex!(T) c)
    {
        T temp = re;
        re = re * c.re - im * c.im;
        im = im * c.re + temp * c.im;
        return this;
    }
    
    Complex!(T) opDivAssign(Complex!(T) c)
    {
        T denominator = c.re * c.re + c.im * c.im;
        T temp = re;
        re = (re * c.re + im * c.im) / denominator;
        im = (im * c.re - temp * c.im) / denominator;
        return this;
    }
    
    Complex!(T) opAdd(T scalar)
    {
        return Complex!(T)(re + scalar, im + scalar);
    }
    
    Complex!(T) opSub(T scalar)
    {
        return Complex!(T)(re + scalar, im + scalar);
    }
    
    Complex!(T) opMul(T scalar)
    {
        return Complex!(T)(re * scalar, im * scalar);
    }
    
    Complex!(T) opDiv(T scalar)
    {
        return Complex!(T)(re / scalar, im / scalar);
    }
    
    Complex!(T) reciprocal()
    {
        T scale = re * re + im * im;
        return Complex!(T)(re / scale, -im / scale);
    }
    
    T magnitude()
    {
        return sqrt(re * re + im * im);
    }
    
    T norm()
    {
        return (re * re + im * im);
    }
    
    string toString()
    {
        auto writer = appender!string();
        formattedWrite(writer, "%s + %si", re, im);
        return writer.data;
    }
}

T abs(T)(Complex!T x)
{
    return sqrt(x.re * x.re + x.im * x.im);
}

T arg(T)(Complex!T x)
{
    return atan2(x.im, x.re);
}

Complex!T pow(T)(Complex!T x, Complex!T n)
{
    T r = abs(x);
    T t = arg(x);
    T c = n.re;
    T d = n.im;
    
    Complex!T res;
    res.re = std.math.pow(r, c) * std.math.exp(-d*t) * cos(c*t + d*log(r));
    res.im = std.math.pow(r, c) * std.math.exp(-d*t) * sin(c*t + d*log(r));

    return res;
}

Complex!T exp(T)(Complex!T s)
{
    return Complex!T(
        std.math.exp(s.re) * cos(s.im), 
        std.math.exp(s.re) * sin(s.im));
}

/*
 * Riemann zeta function
 * ζ(s) = 1/1^s + 1/2^s + 1/3^s + ...
 */
Complex!T zeta(T)(Complex!T s)
{
    return Complex!T(1.0) +
        (s + Complex!T(3.0)) / (s - Complex!T(1.0)) *
        Complex!T(1.0) / pow(Complex!T(2.0), s + Complex!T(1.0));
}

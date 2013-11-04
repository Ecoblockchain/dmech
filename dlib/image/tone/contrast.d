/*
Copyright (c) 2011-2013 Timur Gafarov 

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

module dlib.image.tone.contrast;

private
{
    import dlib.image.image;
    import dlib.image.color;
}

enum ContrastMethod
{
    AverageGray,
    AverageImage,
}

SuperImage contrast(SuperImage a, float k, ContrastMethod method = ContrastMethod.AverageGray)
{
    SuperImage img = a.dup;
    Color4f aver = Color4f(0.0f, 0.0f, 0.0f);

    if (method == ContrastMethod.AverageGray)
    {
        aver = Color4f(0.5f, 0.5f, 0.5f);
    }
    else if (method == ContrastMethod.AverageImage)
    {
        foreach(y; 0..img.height)
        foreach(x; 0..img.width)
        {
            aver += Color4f(a[x, y]);
            a.updateProgress();
        }

        aver /= (img.height * img.width);
        
        a.resetProgress();
    }

    foreach(y; 0..img.height)
    foreach(x; 0..img.width)
    {
        auto col = Color4f(a[x, y]);
        col = ((col - aver) * k + aver);
        img[x, y] = col.convert(img.bitDepth);
        a.updateProgress();
    }
    
    a.resetProgress();

    return img;
}


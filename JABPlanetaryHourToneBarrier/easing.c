//
//  easing.c
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/2/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#include "easing.h"

#include <math.h>
#include "easing.h"
//

// Modeled after the line y = x
double LinearInterpolation(double a, double b)
{
    return (double)(a / b);
}

// Linear easing
double LinearEaseInOut(double x)
{
    return (x <= 0.5) ? x : 1.0 - x;
}

double NormalizedSineEaseInOut(double x, int ordinary_frequency)
{
//    return pow(-(cos(x * ((2 * M_PI) * ordinary_frequency))), gamma);
    return sinf(x * M_PI * ((ordinary_frequency > 0) ? ordinary_frequency : 1));
}

// Sine-pi easing
double SinePiEaseInOutTimesFour(double x)
{
    return sinf(x * M_PI);
}

// Modeled after the parabola y = x^2
double QuadraticEaseIn(double x)
{
    return x * x;
}

// Modeled after the parabola y = -x^2 + 2x
double QuadraticEaseOut(double x)
{
    return -(x * (x - 2));
}

// Modeled after the piecewise quadratic
// y = (1/2)((2x)^2)             ; [0, 0.5)
// y = -(1/2)((2x-1)*(2x-3) - 1) ; [0.5, 1]
double QuadraticEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 2 * x * x;
    }
    else
    {
        return (-2 * x * x) + (4 * x) - 1;
    }
}

// Modeled after the cubic y = x^3
double CubicEaseIn(double x)
{
    return x * x * x;
}

// Modeled after the cubic y = (x - 1)^3 + 1
double CubicEaseOut(double x)
{
    double f = (x - 1);
    return f * f * f + 1;
}

// Modeled after the piecewise cubic
// y = (1/2)((2x)^3)       ; [0, 0.5)
// y = (1/2)((2x-2)^3 + 2) ; [0.5, 1]
double CubicEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 4 * x * x * x;
    }
    else
    {
        double f = ((2 * x) - 2);
        return 0.5 * f * f * f + 1;
    }
}

// Modeled after the quartic x^4
double QuarticEaseIn(double x)
{
    return x * x * x * x;
}

// Modeled after the quartic y = 1 - (x - 1)^4
double QuarticEaseOut(double x)
{
    double f = (x - 1);
    return f * f * f * (1 - x) + 1;
}

// Modeled after the piecewise quartic
// y = (1/2)((2x)^4)        ; [0, 0.5)
// y = -(1/2)((2x-2)^4 - 2) ; [0.5, 1]
double QuarticEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 8 * x * x * x * x;
    }
    else
    {
        double f = (x - 1);
        return -8 * f * f * f * f + 1;
    }
}

// Modeled after the quintic y = x^5
double QuinticEaseIn(double x)
{
    return x * x * x * x * x;
}

// Modeled after the quintic y = (x - 1)^5 + 1
double QuinticEaseOut(double x)
{
    double f = (x - 1);
    return f * f * f * f * f + 1;
}

// Modeled after the piecewise quintic
// y = (1/2)((2x)^5)       ; [0, 0.5)
// y = (1/2)((2x-2)^5 + 2) ; [0.5, 1]
double QuinticEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 16 * x * x * x * x * x;
    }
    else
    {
        double f = ((2 * x) - 2);
        return  0.5 * f * f * f * f * f + 1;
    }
}

// Modeled after quarter-cycle of sine wave
double SineEaseIn(double x)
{
    return sin((x - 1) * M_PI_2) + 1;
}

// Modeled after quarter-cycle of sine wave (different phase)
double SineEaseOut(double x)
{
    return sin(x * M_PI_2);
}

// Modeled after half sine wave
double SineEaseInOut(double x)
{
    return 0.5 * (1 - cos(x * M_PI));
}

// Modeled after shifted quadrant IV of unit circle
double CircularEaseIn(double x)
{
    return 1 - sqrt(1 - (x * x));
}

// Modeled after shifted quadrant II of unit circle
double CircularEaseOut(double x)
{
    return sqrt((2 - x) * x);
}

// Modeled after the piecewise circular function
// y = (1/2)(1 - sqrt(1 - 4x^2))           ; [0, 0.5)
// y = (1/2)(sqrt(-(2x - 3)*(2x - 1)) + 1) ; [0.5, 1]
double CircularEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 0.5 * (1 - sqrt(1 - 4 * (x * x)));
    }
    else
    {
        return 0.5 * (sqrt(-((2 * x) - 3) * ((2 * x) - 1)) + 1);
    }
}

// Modeled after the exponential function y = 2^(10(x - 1))
double ExponentialEaseIn(double x)
{
    return (x == 0.0) ? x : pow(2, 10 * (x - 1));
}

// Modeled after the exponential function y = -2^(-10x) + 1
double ExponentialEaseOut(double x)
{
    return (x == 1.0) ? x : 1 - pow(2, -10 * x);
}

// Modeled after the piecewise exponential
// y = (1/2)2^(10(2x - 1))         ; [0,0.5)
// y = -(1/2)*2^(-10(2x - 1))) + 1 ; [0.5,1]
double ExponentialEaseInOut(double x)
{
    if(x == 0.0 || x == 1.0) return x;
    
    if(x < 0.5)
    {
        return 0.5 * pow(2, (20 * x) - 10);
    }
    else
    {
        return -0.5 * pow(2, (-20 * x) + 10) + 1;
    }
}

// Modeled after the damped sine wave y = sin(13pi/2*x)*pow(2, 10 * (x - 1))
double ElasticEaseIn(double x)
{
    return sin(13 * M_PI_2 * x) * pow(2, 10 * (x - 1));
}

// Modeled after the damped sine wave y = sin(-13pi/2*(x + 1))*pow(2, -10x) + 1
double ElasticEaseOut(double x)
{
    return sin(-13 * M_PI_2 * (x + 1)) * pow(2, -10 * x) + 1;
}

// Modeled after the piecewise exponentially-damped sine wave:
// y = (1/2)*sin(13pi/2*(2*x))*pow(2, 10 * ((2*x) - 1))      ; [0,0.5)
// y = (1/2)*(sin(-13pi/2*((2x-1)+1))*pow(2,-10(2*x-1)) + 2) ; [0.5, 1]
double ElasticEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 0.5 * sin(13 * M_PI_2 * (2 * x)) * pow(2, 10 * ((2 * x) - 1));
    }
    else
    {
        return 0.5 * (sin(-13 * M_PI_2 * ((2 * x - 1) + 1)) * pow(2, -10 * (2 * x - 1)) + 2);
    }
}

// Modeled after the overshooting cubic y = x^3-x*sin(x*pi)
double BackEaseIn(double x)
{
    return x * x * x - x * sin(x * M_PI);
}

// Modeled after overshooting cubic y = 1-((1-x)^3-(1-x)*sin((1-x)*pi))
double BackEaseOut(double x)
{
    double f = (1 - x);
    return 1 - (f * f * f - f * sin(f * M_PI));
}

// Modeled after the piecewise overshooting cubic function:
// y = (1/2)*((2x)^3-(2x)*sin(2*x*pi))           ; [0, 0.5)
// y = (1/2)*(1-((1-x)^3-(1-x)*sin((1-x)*pi))+1) ; [0.5, 1]
double BackEaseInOut(double x)
{
    if(x < 0.5)
    {
        double f = 2 * x;
        return 0.5 * (f * f * f - f * sin(f * M_PI));
    }
    else
    {
        double f = (1 - (2*x - 1));
        return 0.5 * (1 - (f * f * f - f * sin(f * M_PI))) + 0.5;
    }
}

double BounceEaseIn(double x)
{
    return 1 - BounceEaseOut(1 - x);
}

double BounceEaseOut(double x)
{
    if(x < 4/11.0)
    {
        return (121 * x * x)/16.0;
    }
    else if(x < 8/11.0)
    {
        return (363/40.0 * x * x) - (99/10.0 * x) + 17/5.0;
    }
    else if(x < 9/10.0)
    {
        return (4356/361.0 * x * x) - (35442/1805.0 * x) + 16061/1805.0;
    }
    else
    {
        return (54/5.0 * x * x) - (513/25.0 * x) + 268/25.0;
    }
}

double BounceEaseInOut(double x)
{
    if(x < 0.5)
    {
        return 0.5 * BounceEaseIn(x*2);
    }
    else
    {
        return 0.5 * BounceEaseOut(x * 2 - 1) + 0.5;
    }
}

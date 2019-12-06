//
//  easing.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/2/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#ifndef easing_h
#define easing_h

#include <stdio.h>

// Source control...

// Linear interpolation (no easing)
double LinearInterpolation(double a, double b);

// Linear easing
double LinearEaseInOut(double x);

// Sine-pi easing
double SinePiEaseInOutTimesFour(double x);

// Quadratic easing; x^2
double QuadraticEaseIn(double x);
double QuadraticEaseOut(double x);
double QuadraticEaseInOut(double x);

// Cubic easing; x^3
double CubicEaseIn(double x);
double CubicEaseOut(double x);
double CubicEaseInOut(double x);

// Quartic easing; x^4
double QuarticEaseIn(double x);
double QuarticEaseOut(double x);
double QuarticEaseInOut(double x);

// Quintic easing; x^5
double QuinticEaseIn(double x);
double QuinticEaseOut(double x);
double QuinticEaseInOut(double x);

// Sine wave easing; sin(x * PI/2)
double SineEaseIn(double x);
double SineEaseOut(double x);
double SineEaseInOut(double x);

// Circular easing; sqrt(1 - x^2)
double CircularEaseIn(double x);
double CircularEaseOut(double x);
double CircularEaseInOut(double x);

// Exponential easing, base 2
double ExponentialEaseIn(double x);
double ExponentialEaseOut(double x);
double ExponentialEaseInOut(double x);

// Exponentially-damped sine wave easing
double ElasticEaseIn(double x);
double ElasticEaseOut(double x);
double ElasticEaseInOut(double x);

// Overshooting cubic easing;
double BackEaseIn(double x);
double BackEaseOut(double x);
double BackEaseInOut(double x);

// Exponentially-decaying bounce easing
double BounceEaseIn(double x);
double BounceEaseOut(double x);
double BounceEaseInOut(double x);

#endif /* easing_h */

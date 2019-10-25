//
//  GraphView.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 8/25/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "GraphView.h"

@interface GraphView ()
{
    CGFloat _frequency, _amplitude;
}


@end

@implementation GraphView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    CGFloat graphLeading  = CGRectGetMinX(rect);
//    CGFloat graphTrailing = CGRectGetMaxX(rect);
//    CGFloat graphWidth    = CGRectGetWidth(rect);
//    CGFloat graphTop      = CGRectGetMinY(rect);
//    CGFloat offsetY       = CGRectGetMidY(rect);
//    CGFloat stepX         = graphWidth / 10.0;
//    CGFloat graphBottom   = CGRectGetMaxY(rect);
//    CGFloat graphHeight   = CGRectGetHeight(rect);
//    CGFloat stepY         = graphHeight / 10.0;
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextSetLineWidth(context, 0.6);
//    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
//    CGFloat dash[] = {2.0, 2.0};
//    CGContextSetLineDash(context, 0.0, dash, 2);
//
//    int howMany = (graphWidth - graphLeading) / stepX;
//
//    for (int i = 0; i < howMany; i++)
//    {
//        CGContextMoveToPoint(context, graphLeading + i * stepX, graphTop);
//        CGContextAddLineToPoint(context, graphLeading + i * stepX, graphBottom);
//    }
//
//    CGContextStrokePath(context);
//
//    int howManyHorizontal = (graphBottom - graphTop) / stepY;
//    for (int i = 0; i <= howManyHorizontal; i++)
//    {
//        CGContextMoveToPoint(context, graphLeading, graphBottom - i * stepY);
//        CGContextAddLineToPoint(context, graphWidth, graphBottom - i * stepY);
//    }
//
//    CGContextStrokePath(context);
//
//    CGContextSetLineDash(context, 0, NULL, 0); // Remove the dash
//    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
//
//    CGContextMoveToPoint(context, graphLeading, offsetY);
//    for (int i = 0; i < graphTrailing; i++)
//    {
//        CGFloat x = graphLeading + i;
//        CGContextAddLineToPoint(context, x, (_frequency / (graphTrailing)) * sinf(x) + offsetY);
//    }
//
//    CGContextStrokePath(context);
//
//}

- (void)drawRect:(CGRect)rect
{
    CGFloat offsetY       = CGRectGetMidY(rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    unsigned int stepCount = (unsigned int)CGRectGetWidth(rect);
    for (int t = 0; t <= stepCount; t++) {
        CGFloat y = (CGFloat)(_amplitude * sin(t * _frequency + 1.0));

        if (t == 0) {
            CGContextMoveToPoint(context, 0.0, offsetY - y);
        } else {
            CGContextAddLineToPoint(context, t, offsetY - y);
        }
    }

    CGContextStrokePath(context);
}

- (void)drawFrequency:(double)frequency amplitude:(double)amplitude
{
    _frequency = frequency;
    _amplitude = amplitude;
}

@end

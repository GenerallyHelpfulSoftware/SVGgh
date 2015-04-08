//
//  PathUtilities.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2013-2014 Glenn R. Howes

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Created by Glenn Howes on 2/6/13.
//

#import "GHPathUtilities.h"

void CGPathApplyCallbackFunction(void* aVisitor, const CGPathElement *element)
{
    pathVisitor_t   visitor = (__bridge pathVisitor_t)aVisitor;
    visitor(element);
}


@implementation GHPathUtilities
// from http://stackoverflow.com/questions/12024674/get-cgpath-total-length
+ (CGFloat) quadraticBezierLengthFromStartPoint: (CGPoint) start toEndPoint: (CGPoint) end withControlPoint: (CGPoint) control andStep:(CGFloat)step
{
    CGFloat totalLength = 0.0f;
    CGPoint prevPoint = start;
    CGFloat t= step;
    // starting from i = 1, since for i = 0 calulated point is equal to start point
    while(t <= 1.0)
    {
        CGFloat x = (1.0f - t)*(1.0f - t)*start.x + 2.0f*(1.0f - t)*t*control.x + t*t*end.x;
        CGFloat y = (1.0f - t)*(1.0f - t)*start.y + 2.0f*(1.0f - t)*t*control.y + t*t*end.y;
        
        CGPoint diff = CGPointMake(x - prevPoint.x, y - prevPoint.y);
        
        totalLength += sqrtf(diff.x*diff.x + diff.y*diff.y); // Pythagorean
        
        prevPoint = CGPointMake(x, y);
        
        if(t < 1.0)
        {
            t += step;
            if(t > 1.0)
            {
                t = 1.0;
            }
        }
        else
        {
            t += step;
        }
    }
    
    return totalLength;
}

+(CGFloat) cubicSplineLengthFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint withControlPoint1:(CGPoint)controlPoint1
                         withControlPoint2:(CGPoint)controlPoint2 andStep:(CGFloat)step
{
    CGFloat A = endPoint.x-3.0f*controlPoint2.x+3.0f*controlPoint1.x-startPoint.x;
    CGFloat B = 3.0f*controlPoint2.x-6.0f*controlPoint1.x+3.0f*startPoint.x;
    CGFloat C = 3.0f*controlPoint1.x-3.0f*startPoint.x;
    CGFloat D = startPoint.x;
    CGFloat E = endPoint.y-3.0f*controlPoint2.y+3.0f*controlPoint1.y-startPoint.y;
    CGFloat F = 3.0f*controlPoint2.y-6.0f*controlPoint1.y+3.0f*startPoint.y;
    CGFloat G = 3.0f*controlPoint1.y-3.0f*startPoint.y;
    CGFloat H = startPoint.y;
    
    CGFloat totalLength = 0.0f;
    CGPoint prevPoint = startPoint;
    CGFloat t= step;
    // starting from i = 1, since for i = 0 calulated point is equal to start point
    while(t <= 1.0)
    {
        CGFloat x = (((A*t) + B)*t + C)*t + D;
        CGFloat y = (((E*t) + F)*t + G)*t + H;
        
        CGPoint diff = CGPointMake(x - prevPoint.x, y - prevPoint.y);
        
        totalLength += sqrtf(diff.x*diff.x + diff.y*diff.y); // Pythagorean
        
        prevPoint = CGPointMake(x, y);
        
        if(t < 1.0)
        {
            t += step;
            if(t > 1.0)
            {
                t = 1.0;
            }
        }
        else
        {
            t += step;
        }
    }
    
    return totalLength;
}


+ (CGFloat) calculateCubicSplineStepFromFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint withControlPoint1:(CGPoint)controlPoint1
                                     withControlPoint2:(CGPoint)controlPoint2
{
    CGFloat result = 0.5;
    CGFloat lastLength = [GHPathUtilities cubicSplineLengthFromStartPoint:startPoint toEndPoint:endPoint withControlPoint1:controlPoint1 withControlPoint2:controlPoint2 andStep:1.0];
    CGFloat smallestStep = 1.0/1024.0;
    while(result > smallestStep)
    {
        CGFloat thisLength = [GHPathUtilities cubicSplineLengthFromStartPoint:startPoint toEndPoint:endPoint withControlPoint1:controlPoint1 withControlPoint2:controlPoint2 andStep:result];
        CGFloat delta = fabs(thisLength-lastLength);
        if(delta < thisLength/256.0 && delta < lastLength/256.0)
        {
            break;
        }
        else
        {
            result /= 2.0;
        }
        lastLength = thisLength;
    }
    return result;
}


+ (CGFloat) calculateQuadraticSplineStepFromStartPoint: (CGPoint) start toEndPoint: (CGPoint) end withControlPoint: (CGPoint) control
{
    CGFloat result = 0.5;
    CGFloat lastLength = [GHPathUtilities quadraticBezierLengthFromStartPoint:start toEndPoint:end withControlPoint:control andStep:1.0];
    CGFloat smallestStep = 1.0/1024.0;
    while(result > smallestStep)
    {
        CGFloat thisLength = [GHPathUtilities quadraticBezierLengthFromStartPoint:start toEndPoint:end withControlPoint:control andStep:result];
        CGFloat delta = fabs(thisLength-lastLength);
        if(delta < thisLength/256.0 && delta < lastLength/256.0)
        {
            break;
        }
        else
        {
            result /= 2.0;
        }
    }
    return result;
}

+(CGFloat) totalLengthOfCGPath:(CGPathRef)pathRef
{
    __block  CGPoint currentPoint = CGPointZero;
    __block  CGFloat runningLength = 0;
    
    __block pathVisitor_t     callback =  ^(const CGPathElement* aPathElement){
        
        __block pathVisitor_t lineToCallback = ^(const CGPathElement* lineSegmentElement){
            CGPoint nextPoint = lineSegmentElement->points[0];
            CGFloat deltaX = nextPoint.x-currentPoint.x;
            CGFloat deltaY = nextPoint.y-currentPoint.y;
            if(fabs(deltaX)>0.004 || fabs(deltaY) > 0.004)
            {
                CGFloat segmentLength = sqrtf(deltaX*deltaX+deltaY*deltaY);
                CGFloat lengthLeft = segmentLength;
                
                runningLength += lengthLeft;
            }
            currentPoint = nextPoint;
            
        };
        
        switch (aPathElement->type)
        {
            case kCGPathElementMoveToPoint:
            {
                currentPoint = aPathElement->points[0];
            }
                break;
            case kCGPathElementAddLineToPoint:
            {
                lineToCallback(aPathElement);
            }
                break;
            case kCGPathElementAddQuadCurveToPoint:
            {
                CGPoint startPoint = currentPoint;
                CGPoint controlPoint = aPathElement->points[0];
                CGPoint nextPoint = aPathElement->points[1];
                CGFloat approximationStep = [GHPathUtilities calculateQuadraticSplineStepFromStartPoint:startPoint toEndPoint:nextPoint withControlPoint:controlPoint];
                CGFloat t =  approximationStep;
                
                while(t <= 1.0)
                {
                    CGFloat x = (1.0f - t)*(1.0f - t)*startPoint.x + 2.0f*(1.0f - t)*t*controlPoint.x + t*t*nextPoint.x;
                    CGFloat y = (1.0f - t)*(1.0f - t)*startPoint.y + 2.0f*(1.0f - t)*t*controlPoint.y + t*t*nextPoint.y;
                    CGPoint linePoint = CGPointMake(x, y);
                    CGPathElement   approximationElement;
                    approximationElement.type = kCGPathElementAddLineToPoint;
                    approximationElement.points = &linePoint;
                    lineToCallback(&approximationElement);
                    if(t < 1.0)
                    {
                        t += approximationStep;
                        if(t > 1.0)
                        {
                            t = 1.0;
                        }
                    }
                    else
                    {
                        t += approximationStep;
                    }
                }
                currentPoint = nextPoint;
                
            }
                break;
            case kCGPathElementAddCurveToPoint:
            {
                CGPoint controlPoint1 = aPathElement->points[0];
                CGPoint controlPoint2 = aPathElement->points[1];
                CGPoint nextPoint = aPathElement->points[2];
                CGPoint startPoint = currentPoint;
                
                CGFloat A = nextPoint.x-3.0f*controlPoint2.x+3.0f*controlPoint1.x-startPoint.x;
                CGFloat B = 3.0f*controlPoint2.x-6.0f*controlPoint1.x+3.0f*startPoint.x;
                CGFloat C = 3.0f*controlPoint1.x-3.0f*startPoint.x;
                CGFloat D = startPoint.x;
                CGFloat E = nextPoint.y-3.0f*controlPoint2.y+3.0f*controlPoint1.y-startPoint.y;
                CGFloat F = 3.0f*controlPoint2.y-6.0f*controlPoint1.y+3.0f*startPoint.y;
                CGFloat G = 3.0f*controlPoint1.y-3.0f*startPoint.y;
                CGFloat H = startPoint.y;
                
                CGFloat approximationStep = [GHPathUtilities calculateCubicSplineStepFromFromStartPoint:startPoint toEndPoint:nextPoint withControlPoint1:controlPoint1 withControlPoint2:(CGPoint)controlPoint2];
                CGFloat t =  approximationStep;
                while(t <= 1.0)
                {
                    CGFloat x = (((A*t) + B)*t + C)*t + D;
                    CGFloat y = (((E*t) + F)*t + G)*t + H;
                    CGPoint linePoint = CGPointMake(x, y);
                    CGPathElement   approximationElement;
                    approximationElement.type = kCGPathElementAddLineToPoint;
                    approximationElement.points = &linePoint;
                    lineToCallback(&approximationElement);
                    if(t < 1.0)
                    {
                        t += approximationStep;
                        if(t > 1.0)
                        {
                            t = 1.0;
                        }
                    }
                    else
                    {
                        t += approximationStep;
                    }
                }
                currentPoint = nextPoint;
            }
                break;
            case kCGPathElementCloseSubpath:
                break;
            default:
            {
            }
                break;
        }
    };
    
    CGPathApply(pathRef, (__bridge void *)callback, CGPathApplyCallbackFunction);
    return runningLength;
}

+(void) findPointAndVectorAtDistance:(CGFloat)length intoPath:(CGPathRef)pathRef intoCallback:(pointAndVectorCallback_t)callback
{
    __block CGPoint point = CGPointZero;
    __block CGPoint vector = CGPointMake(1, 0);
    if(pathRef != 0)
    {
        __block CGFloat nextOffset = length;
        __block  CGPoint currentPoint = CGPointZero;
        __block  CGFloat runningLength = 0;
        __block  BOOL foundIt = NO;
        __block pathVisitor_t     callback =  ^(const CGPathElement* aPathElement){
            
            if(!foundIt)
            {
                __block pathVisitor_t lineToCallback = ^(const CGPathElement* lineSegmentElement){
                    CGPoint nextPoint = lineSegmentElement->points[0];
                    CGFloat deltaX = nextPoint.x-currentPoint.x;
                    CGFloat deltaY = nextPoint.y-currentPoint.y;
                    if(fabs(deltaX)>0.004 || fabs(deltaY) > 0.004)
                    {
                        CGFloat segmentLength = sqrtf(deltaX*deltaX+deltaY*deltaY);
                        CGFloat lengthLeft = segmentLength;
                        while(lengthLeft > 0 && !foundIt)
                        {
                            if(nextOffset > (runningLength+lengthLeft))
                            {
                                runningLength += lengthLeft;
                                lengthLeft = 0.0;
                                currentPoint = nextPoint;
                            }
                            else
                            {
                                foundIt = YES;
                                CGFloat distanceIntoSegment = nextOffset-runningLength;
                                CGPoint thePoint = CGPointMake((distanceIntoSegment/segmentLength)*deltaX+currentPoint.x, (distanceIntoSegment/segmentLength)*deltaY+currentPoint.y);
                                
                                vector = CalculateForward(currentPoint, nextPoint);
                                point = thePoint;
                                currentPoint = thePoint;
                            }
                        }
                    }
                    currentPoint = nextPoint;
                    
                };
                
                switch (aPathElement->type)
                {
                    case kCGPathElementMoveToPoint:
                    {
                        currentPoint = aPathElement->points[0];
                    }
                        break;
                    case kCGPathElementAddLineToPoint:
                    {
                        lineToCallback(aPathElement);
                    }
                        break;
                    case kCGPathElementAddQuadCurveToPoint:
                    {
                        CGPoint startPoint = currentPoint;
                        CGPoint controlPoint = aPathElement->points[0];
                        CGPoint nextPoint = aPathElement->points[1];
                        CGFloat approximationStep = [GHPathUtilities calculateQuadraticSplineStepFromStartPoint:startPoint toEndPoint:nextPoint withControlPoint:controlPoint];
                        CGFloat t =  approximationStep;
                        
                        while(t <= 1.0)
                        {
                            CGFloat x = (1.0f - t)*(1.0f - t)*startPoint.x + 2.0f*(1.0f - t)*t*controlPoint.x + t*t*nextPoint.x;
                            CGFloat y = (1.0f - t)*(1.0f - t)*startPoint.y + 2.0f*(1.0f - t)*t*controlPoint.y + t*t*nextPoint.y;
                            CGPoint linePoint = CGPointMake(x, y);
                            CGPathElement   approximationElement;
                            approximationElement.type = kCGPathElementAddLineToPoint;
                            approximationElement.points = &linePoint;
                            lineToCallback(&approximationElement);
                            if(t < 1.0)
                            {
                                t += approximationStep;
                                if(t > 1.0)
                                {
                                    t = 1.0;
                                }
                            }
                            else
                            {
                                t += approximationStep;
                            }
                        }
                        currentPoint = nextPoint;
                        
                    }
                        break;
                    case kCGPathElementAddCurveToPoint:
                    {
                        CGPoint controlPoint1 = aPathElement->points[0];
                        CGPoint controlPoint2 = aPathElement->points[1];
                        CGPoint nextPoint = aPathElement->points[2];
                        CGPoint startPoint = currentPoint;
                        
                        CGFloat A = nextPoint.x-3.0f*controlPoint2.x+3.0f*controlPoint1.x-startPoint.x;
                        CGFloat B = 3.0f*controlPoint2.x-6.0f*controlPoint1.x+3.0f*startPoint.x;
                        CGFloat C = 3.0f*controlPoint1.x-3.0f*startPoint.x;
                        CGFloat D = startPoint.x;
                        CGFloat E = nextPoint.y-3.0f*controlPoint2.y+3.0f*controlPoint1.y-startPoint.y;
                        CGFloat F = 3.0f*controlPoint2.y-6.0f*controlPoint1.y+3.0f*startPoint.y;
                        CGFloat G = 3.0f*controlPoint1.y-3.0f*startPoint.y;
                        CGFloat H = startPoint.y;
                        
                        CGFloat approximationStep = [GHPathUtilities calculateCubicSplineStepFromFromStartPoint:startPoint toEndPoint:nextPoint withControlPoint1:controlPoint1 withControlPoint2:(CGPoint)controlPoint2];
                        CGFloat t =  approximationStep;
                        while(t <= 1.0)
                        {
                            CGFloat x = (((A*t) + B)*t + C)*t + D;
                            CGFloat y = (((E*t) + F)*t + G)*t + H;
                            CGPoint linePoint = CGPointMake(x, y);
                            CGPathElement   approximationElement;
                            approximationElement.type = kCGPathElementAddLineToPoint;
                            approximationElement.points = &linePoint;
                            lineToCallback(&approximationElement);
                            if(t < 1.0)
                            {
                                t += approximationStep;
                                if(t > 1.0)
                                {
                                    t = 1.0;
                                }
                            }
                            else
                            {
                                t += approximationStep;
                            }
                        }
                        currentPoint = nextPoint;
                    }
                        break;
                    case kCGPathElementCloseSubpath:
                        break;
                    default:
                    {
                    }
                        break;
                }
            }
        };
        
        CGPathApply(pathRef, (__bridge void *)callback, CGPathApplyCallbackFunction);
    }
    callback(point, vector);
}
@end


CGPoint CalculateForward(CGPoint startPoint, CGPoint endPoint)
{
    CGPoint result = CGPointMake(0.0, 1.0); // for the case of a zero length segment
    CGFloat deltaX = endPoint.x-startPoint.x;
    CGFloat deltaY = endPoint.y-startPoint.y;
    
    if(deltaX == 0.0)
    {
        if(deltaY > 0.0)
        {
            result = CGPointMake(-1.0, 0.0);
        }
        else if(deltaY < 0.0)
        {
            result = CGPointMake(1.0, 0.0);
        }
    }
    else if(deltaY == 0.0)
    {
        if(deltaX > 0.0)
        {
            result = CGPointMake(0.0, 1.0);
        }
        else
        {
            result = CGPointMake(0.0, -1.0);
        }
    }
    else
    {
        CGFloat length = sqrtf(deltaX*deltaX+deltaY*deltaY);
        CGFloat normalizedDeltaX = deltaX/length;
        CGFloat normalizedDeltaY = deltaY/length; // scale to the unit vector
        result = CGPointMake(-1.0f*normalizedDeltaY, normalizedDeltaX);
    }
    
    return result;
}
//
//  GHPathUtilities.h
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

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreGraphics;
#else
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^pathVisitor_t)(const CGPathElement * element);

/*! @brief block definition that returns the point on a path and it's direction at that point
 @param point the point being returned
 @param vector the direction of a path at that point
 @see findPointAndVectorAtDistance:intoPath:intoCallback
 */
typedef void (^pointAndVectorCallback_t)(CGPoint point, CGPoint vector);


void CGPathApplyCallbackFunction(void*   aVisitor, const CGPathElement *  element);

@interface GHPathUtilities : NSObject

/*! @brief approximate the distance along the given quadratic spline section from the start to the end point
* @param startPoint beginning of a quadratic spline
* @param endPoint ending of a quadratic spline
* @param controlPoint the control point for this spline
* @return the length along the path between the two points (approximately)
*/
+ (CGFloat) calculateQuadraticSplineStepFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint) endPoint withControlPoint:(CGPoint)controlPoint;
/*! @brief approximate the distance along the given quadratic spline with a provided step approximation

* @param startPoint beginning of a quadratic spline
* @param endPoint ending of a quadratic spline
* @param controlPoint the control point for this spline
* @param step the length to approixmate curves with straight lines (smaller is slower and more accurate)
* @return the length along the path between the two points (approximately)
*/
+ (CGFloat) quadraticBezierLengthFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint) endPoint withControlPoint:(CGPoint) controlPoint andStep:(CGFloat)step;

/*! @brief approximate the distance along the given cubic spline section from the start to the end point
 * @param startPoint beginning of a cubic spline
 * @param endPoint ending of a quadratic spline
 * @param controlPoint1 the first control point for this spline
 * @param controlPoint2 the second control point for this spline
 * @return the length along the path between the two points (approximately)
 */
+ (CGFloat) calculateCubicSplineStepFromFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint withControlPoint1:(CGPoint)controlPoint1
                                     withControlPoint2:(CGPoint)controlPoint2;

/*! @brief approximate the distance along the given cubic spline with a provided step approximation
 
 * @param startPoint beginning of a cubic spline
 * @param endPoint ending of a cubic spline
 * @param controlPoint1 the first control point for this spline
 * @param controlPoint2 the second control point for this spline
 * @param step the length to approixmate curves with straight lines (smaller is slower and more accurate)
 * @return the length along the path between the two points (approximately)
 */
+(CGFloat) cubicSplineLengthFromStartPoint:(CGPoint)startPoint toEndPoint:(CGPoint)endPoint withControlPoint1:(CGPoint)controlPoint1
                         withControlPoint2:(CGPoint)controlPoint2 andStep:(CGFloat)step;


/*! @brief get the total length of a Core Graphics path (somewhat of an approximation, does not include jumps via move to)
 * @param aPath a Core Graphics path to find the lengh of
 * @return a length
 */
+(CGFloat) totalLengthOfCGPath:(CGPathRef)aPath;

/*! @brief go a given distance along a path and find out the location of the point at that distance and the direction vector at that point
 * @param length a distance along the path to go
 * @param aPath a Core Graphics path to test
 * @param callback the block to call when you retrieve this information
 */
+(void) findPointAndVectorAtDistance:(CGFloat)length intoPath:(CGPathRef)aPath intoCallback:(pointAndVectorCallback_t)callback;
@end

__attribute__((deprecated)) CGPoint CalculateForward(CGPoint startPoint, CGPoint endPoint);


/*! @brief given the start and end of a line segment, calculate the perpendicular normal to them
 * @param startPoint
 * @param endPoint
 */
CGPoint CalculateNormal(CGPoint startPoint, CGPoint endPoint);

NS_ASSUME_NONNULL_END

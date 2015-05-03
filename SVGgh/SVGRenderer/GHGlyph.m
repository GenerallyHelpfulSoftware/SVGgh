//
//  Glyph.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2011-2014 Glenn R. Howes

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
//  Created by Glenn Howes on 2/3/13.


#import "GHGlyph.h"
#import "SVGUtilities.h"
#import "GHPathUtilities.h"
#import "SVGPathGenerator.h"

@interface GHGlyph()
@property(nonatomic, readwrite) NSString* fillDescription;
@property(nonatomic, readwrite) NSString* strokeDescription;
@property(nonatomic, readwrite) CGFloat rotationAngleInRadians;
@property(nonatomic, assign) CGFloat strokeWidth;
@property(nonatomic, readwrite) BOOL notRendering;
-(void) setRenderPoint:(CGPoint)thePoint withPerpendicular:(CGPoint) perpendicularVector;
@end


@implementation GHGlyph

+(void) positionGlyphs:(NSArray*)listOfGlyphs alongCGPath:(CGPathRef)pathRef
{
    __block NSUInteger      glyphIndex = 0;
    __block GHGlyph*          currentGlyph = [listOfGlyphs objectAtIndex:glyphIndex++];
    CGRect runBox = currentGlyph.runRect;
    __block CGFloat startOffset = -1.0*runBox.origin.x;
    __block CGFloat nextOffset = runBox.size.width/2.0+startOffset;
    __block  CGPoint currentPoint = CGPointZero;
    __block  CGFloat runningLength = 0;
    
     __block pathVisitor_t     callback =  ^(const CGPathElement* aPathElement){
        if(currentGlyph != nil)
        {
            __block pathVisitor_t lineToCallback = ^(const CGPathElement* lineSegmentElement){
                CGPoint nextPoint = lineSegmentElement->points[0];
                CGFloat deltaX = nextPoint.x-currentPoint.x;
                CGFloat deltaY = nextPoint.y-currentPoint.y;
                if(fabs(deltaX)>0.004 || fabs(deltaY) > 0.004)
                {
                    CGFloat segmentLength = sqrtf(deltaX*deltaX+deltaY*deltaY);
                    CGFloat lengthLeft = segmentLength;
                    CGPoint perpendicularVector = CalculateForward(currentPoint, nextPoint);
                    while(lengthLeft > 0 && currentGlyph != nil)
                    {
                        if(nextOffset > (runningLength+lengthLeft))
                        {
                            runningLength += lengthLeft;
                            lengthLeft = 0.0;
                            currentPoint = nextPoint;
                        }
                        else
                        {
                            CGFloat distanceIntoSegment = nextOffset-runningLength;
                            CGPoint thePoint = CGPointMake((distanceIntoSegment/segmentLength)*deltaX+currentPoint.x,
                                                           (distanceIntoSegment/segmentLength)*deltaY+currentPoint.y+currentGlyph.offset.y);
                            [currentGlyph setMidRenderPoint:thePoint withPerpendicular:perpendicularVector];
                            lengthLeft -= distanceIntoSegment;
                            runningLength = nextOffset;
                            if(glyphIndex < [listOfGlyphs count])
                            {
                                currentGlyph = [listOfGlyphs objectAtIndex:glyphIndex++];
                                CGRect runBox = currentGlyph.runRect;
                                nextOffset = currentGlyph.offset.x+runBox.size.width/2.0;
                            }
                            else
                            {
                                currentGlyph = nil;
                            }
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
    
    while(currentGlyph != nil)
    {
        currentGlyph.notRendering = YES;
        if(glyphIndex < [listOfGlyphs count])
        {
            currentGlyph = [listOfGlyphs objectAtIndex:glyphIndex++];
        }
        else
        {
            currentGlyph = nil;
        }
    }

}


-(id) initWithDictionary:(NSDictionary *)theAttributes textAttributes:(NSDictionary*) tAttributes font:(CTFontRef)aFont glyph:(CGGlyph)aGlyph transform:(CGAffineTransform)aTransform offset:(CGPoint)theOffset runBox:(CGRect)runBox andWidth:(CGFloat)theWidth
{
    if(nil != (self = [super initWithDictionary:theAttributes]))
    {
        _font = aFont;
        CFRetain(_font);
        _glyph = aGlyph;
        _runRect = CGRectApplyAffineTransform(runBox, aTransform);
        _width = theWidth;
        _transform = aTransform;
        _offset = theOffset;        _textAttributes = tAttributes;
        _fillDescription = [SVGToQuartz valueForStyleAttribute:@"fill" fromDefinition:theAttributes];
        _strokeDescription = [SVGToQuartz valueForStyleAttribute:@"stroke" fromDefinition:theAttributes];
        
        NSString* strokeWidthDescripion = [SVGToQuartz valueForStyleAttribute:@"stroke-width" fromDefinition:theAttributes];
		if([strokeWidthDescripion length])
		{
			_strokeWidth = [strokeWidthDescripion floatValue];
		}
        else
        {
            _strokeWidth = -1;
        }
    }
    return self;
}

-(NSUInteger)calculatedHash
{
    NSUInteger result = [super calculatedHash];
    result += [self.textAttributes hash];
    result += CFHash(self.font);
    
    NSUInteger multiplier = 31;
    result+= multiplier*self.offset.x;
    multiplier*=11;
    result+= multiplier*self.offset.y;
    multiplier*=11;
    result+= multiplier*self.offset.y;
    multiplier*=11;
    result+= multiplier*_transform.a;
    multiplier*=11;
    result+= multiplier*_transform.b;
    multiplier*=11;
    result+= multiplier*_transform.c;
    multiplier*=11;
    result+= multiplier*_transform.d;
    multiplier*=11;
    result+= multiplier*_transform.tx;
    multiplier*=11;
    result+= multiplier*_transform.ty;
    multiplier*=11;
    result+= multiplier*self.glyph;
    
    return result;
}

-(CGRect) boundingBox
{
    CGRect result = CTFontGetBoundingRectsForGlyphs(
                       self.font,
                       kCTFontOrientationDefault,
                       &_glyph,
                       NULL, 1);
    return result;
}

-(BOOL)isEqual:(id)object
{
    BOOL result = object == self;
    
    if(!result && [super isEqual:object])
    {
        GHGlyph* objectAsGlyph = (GHGlyph*)object;
        result = [self.textAttributes isEqual:objectAsGlyph.textAttributes]
                && CGPointEqualToPoint(self.offset, objectAsGlyph.offset)
                && CGAffineTransformEqualToTransform(self.transform, objectAsGlyph.transform)
                && self.glyph == objectAsGlyph.glyph;
    }
    
    return result;
}

-(void) dealloc
{
    if(_font)
    {
        CFRelease(_font);
    }
}

-(void) setMidRenderPoint:(CGPoint)midBaselinePoint withPerpendicular:(CGPoint) perpendicularVector
{
    CGFloat radius = self.runRect.size.width/2.0;
    CGFloat rotationAngle = atan2(perpendicularVector.x, perpendicularVector.y)-M_PI_2;
    CGFloat deltaX = radius*sin (rotationAngle);
    CGFloat deltaY = (radius)*cos(rotationAngle);
    
    CGPoint zeroPoint = CGPointMake(midBaselinePoint.x+deltaX, midBaselinePoint.y+deltaY);
    [self setRenderPoint:zeroPoint withPerpendicular:perpendicularVector];
}

-(void) setRenderPoint:(CGPoint)thePoint withPerpendicular:(CGPoint) perpendicularVector
{
    self.rotationAngleInRadians = atan2(perpendicularVector.x, perpendicularVector.y);
    _renderPoint = thePoint;
}

+(CGRect)rectForGlyphs:(NSArray*)listOfGlyphs
{
    CGRect result = CGRectZero;
    for(GHGlyph* aGlyph in listOfGlyphs)
    {
        if(!aGlyph.notRendering)
        {
            CGPathRef letter = CTFontCreatePathForGlyph(aGlyph.font, aGlyph.glyph, NULL);
            CGPoint renderPoint = aGlyph.renderPoint;
            CGAffineTransform glyphTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, renderPoint.x, renderPoint.y);
            glyphTransform = CGAffineTransformScale(glyphTransform, 1.0, -1.0);
            glyphTransform = CGAffineTransformRotate(glyphTransform, aGlyph.rotationAngleInRadians);
            glyphTransform = CGAffineTransformTranslate(glyphTransform, 0.0, -aGlyph.offset.y);
            CGRect pathBounds = CGPathGetBoundingBox(letter);
            pathBounds = CGRectApplyAffineTransform(pathBounds, glyphTransform);
            CGPathRelease(letter);
            if(CGRectIsEmpty(result))
            {
                result = pathBounds;
            }
            else
            {
                result = CGRectUnion(result, pathBounds);
            }
        }
    }
    return result;
}

-(BOOL) isPointInBoundingBox:(CGPoint)aPoint
{
    BOOL result = NO;
    if(!self.notRendering)
    {
        CGPathRef letter = CTFontCreatePathForGlyph(self.font, self.glyph, NULL);
        CGAffineTransform glyphTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, self.renderPoint.x, self.renderPoint.y);
        glyphTransform = CGAffineTransformScale(glyphTransform, 1.0, -1.0);
        glyphTransform = CGAffineTransformRotate(glyphTransform, self.rotationAngleInRadians);
        glyphTransform = CGAffineTransformTranslate(glyphTransform, 0.0, -self.offset.y);
        CGRect pathBounds = CGPathGetBoundingBox(letter);
        pathBounds = CGRectApplyAffineTransform(pathBounds, glyphTransform);
        CGPathRelease(letter);
        
        result = CGRectContainsPoint(pathBounds, aPoint);
    }
    return result;
}

-(void) addPathToContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>) svgContext
{
    if(!self.notRendering)
    {
        CGAffineTransform glyphTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, self.renderPoint.x, self.renderPoint.y);
        glyphTransform = CGAffineTransformScale(glyphTransform, 1.0, -1.0);
        glyphTransform = CGAffineTransformRotate(glyphTransform, self.rotationAngleInRadians);
        glyphTransform = CGAffineTransformTranslate(glyphTransform, 0.0, -self.offset.y);
        CGPathRef letter = CTFontCreatePathForGlyph(self.font, self.glyph, &glyphTransform);
        CGContextSaveGState(quartzContext);
        
        CGContextAddPath(quartzContext, letter);
        
        
        
        CGContextRestoreGState(quartzContext);
        CGPathRelease(letter);
    }
}

-(void)addGlyphsToArray:(NSMutableArray*)glyphList  withSVGContext:(id<SVGContext>)svgContext
{
    [glyphList addObject:self];
}

-(void)addGlyphsToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    [self addPathToContext:quartzContext withSVGContext:svgContext];
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    [self addGlyphsToContext:quartzContext withSVGContext:svgContext];
}

@end



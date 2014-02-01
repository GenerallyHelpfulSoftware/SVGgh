//
//  GHGradient.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2012-2014 Glenn R. Howes

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
//  Created by Glenn Howes on 6/20/12.

#import "GHGradient.h"
#import "SVGGradientUtilities.h"

@interface GHGradientStop : GHAttributedObject
{
}
-(UIColor*) colorWithSVGContext:(id<SVGContext>)svgContext;
@property(readonly) CGFloat     offset;
@end

@interface GHGradient ()
{
    NSArray* stops;
}
-(CGGradientRef) newGradientRefWithSVGContext:(id<SVGContext>)svgContext;
-(BOOL) useUserSpace;
@end


@implementation GHGradient

-(BOOL) useUserSpace
{
    BOOL result = [[self.attributes objectForKey:@"gradientUnits"] isEqualToString:@"userSpaceOnUse"];
    return result;
}

-(id) initWithDictionary:(NSDictionary*)theDefinition
{
	if(nil != (self = [super initWithDictionary:theDefinition]))
	{
		NSArray* contents = [theDefinition objectForKey:kContentsElementName];
		NSMutableArray* mutableChildren = [[NSMutableArray alloc] initWithCapacity:[contents count]];
        id      defaultStopColor = [self.attributes objectForKey:@"stop-color"];
        id      defaultStopOpacity = [self.attributes objectForKey:@"stop-opacity"];
        
        for(id aChild in contents)
		{
			if([aChild isKindOfClass:[NSDictionary class]])
			{
				NSDictionary* aDefinition = (NSDictionary*)aChild;				
				NSString*	elementName = [aDefinition objectForKey:kElementName];
								
				if([elementName isEqualToString:@"stop"])
				{
                    NSDictionary* childAttributes = [aDefinition objectForKey:@"attributes"];
                    NSDictionary* childAttributesToUse = childAttributes;
                    NSString*  stopColorObject = [childAttributes objectForKey:@"stop-color"];
                    NSString* stopOpacityObject = [childAttributesToUse objectForKey:@"stop-opacity"];
                    NSString* styleString = [childAttributes objectForKey:@"style"];
                    
                    if(styleString.length)
                    {
                        NSDictionary* newStyles =  [SVGToQuartz dictionaryForStyleAttributeString:styleString];
                        if(stopOpacityObject.length == 0)
                        {
                            stopOpacityObject = [newStyles objectForKey:@"stop-opacity"];
                        }
                        if(stopColorObject.length == 0)
                        {
                            stopColorObject = [newStyles objectForKey:@"stop-color"];
                        }
                    }
                    
                    if(defaultStopColor != nil && [stopColorObject isEqualToString:@"inherit"])
                    {
                        childAttributesToUse = [childAttributesToUse mutableCopy];
                        [(NSMutableDictionary*)childAttributesToUse setValue:defaultStopColor forKey:@"stop-color"];
                        childAttributesToUse = [childAttributesToUse copy];
                    }
                    if(defaultStopOpacity != nil && [stopOpacityObject isEqualToString:@"inherit"])
                    {
                        childAttributesToUse = [childAttributesToUse mutableCopy];
                        [(NSMutableDictionary*)childAttributesToUse setValue:defaultStopOpacity forKey:@"stop-opacity"];
                        childAttributesToUse = [childAttributesToUse copy];
                    }
                    if(childAttributesToUse != childAttributes)
                    {
                        NSMutableDictionary* newNefinition = [aDefinition mutableCopy];
                        [newNefinition setValue:childAttributesToUse forKey:@"attributes"];
                        aDefinition = [newNefinition copy];
                    }
					GHGradientStop* aGroup = [[GHGradientStop alloc] initWithDictionary:aDefinition];
					[mutableChildren addObject:aGroup];
				}
            }
		}
		if([mutableChildren count])
		{
			stops = [mutableChildren copy];
		}
	}
	return self;
}

-(CGGradientRef) newGradientRefWithSVGContext:(id<SVGContext>)svgContext
{
    CFMutableArrayRef colors = CFArrayCreateMutable(kCFAllocatorDefault, (CFIndex)[stops count], &kCFTypeArrayCallBacks);
    CGFloat* locations = malloc(sizeof(CGFloat)*[stops count]);
    
    
    UIColor* savedColor = [svgContext currentColor];
    NSString* colorString = [self.attributes objectForKey:@"color"];
    if([colorString isEqualToString:@"inherit"] || [colorString length] == 0)
    {
    }
    else if([colorString length])
    {
        UIColor* colorToDefaultTo = [svgContext colorForSVGColorString:colorString];
        [svgContext setCurrentColor:colorToDefaultTo];
    }
    
    
    NSUInteger  index = 0;
    CGFloat minimumOffset = 0.0;
    for(GHGradientStop* aStop in stops)
    {
        CGColorRef stopColor = [aStop colorWithSVGContext:svgContext].CGColor;
        if(stopColor == 0) stopColor = [UIColor blackColor].CGColor;
        CFArrayAppendValue(colors, stopColor);
        CGFloat nominalOffset = aStop.offset;
        
        if(nominalOffset > 1.0)
        {
            nominalOffset = 1.0;
        }
        else if (nominalOffset < 0.0)
        {
            nominalOffset = 0.0;
        }
        if(nominalOffset < minimumOffset)
        {
            nominalOffset = minimumOffset;
            if(index > 0)
            {
                locations[index-1] -= 0.000000000001;
            }
        }
        minimumOffset = nominalOffset;
        locations[index++] = nominalOffset;
    }
    [svgContext setCurrentColor:savedColor];
    
    CGGradientRef result = CGGradientCreateWithColors([SVGGradientUtilities colorSpace],
                                             colors, locations);
    CFRelease(colors);
    free(locations);
    return result;
}


-(void) fillPathToContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    
}
@end

@implementation GHLinearGradient
-(void) fillPathToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect)objectBox
{
    NSString* x1 = [self.attributes objectForKey:@"x1"];
    NSString* x2 = [self.attributes objectForKey:@"x2"];
    NSString* y1 = [self.attributes objectForKey:@"y1"];
    NSString* y2 = [self.attributes objectForKey:@"y2"];
    CGFloat     x1Float = [SVGGradientUtilities extractFractionFromCoordinateString:x1  givenDefault:0.0];
    CGFloat     x2Float = [SVGGradientUtilities extractFractionFromCoordinateString:x2  givenDefault:1.0];
    CGFloat     y1Float = [SVGGradientUtilities extractFractionFromCoordinateString:y1  givenDefault:0.0];
    CGFloat     y2Float = [SVGGradientUtilities extractFractionFromCoordinateString:y2  givenDefault:1.0];
    
    CGContextSaveGState(quartzContext);
    if(!CGContextIsPathEmpty(quartzContext))
    {
        CGContextClip(quartzContext);
    }
    if(![[self.attributes objectForKey:@"gradientUnits"] isEqualToString:@"userSpaceOnUse"])
    {
        CGFloat deltaX = x2Float-x1Float;
        CGFloat deltaY  = y2Float-y1Float;
        if(deltaX != 0.0 && deltaY != 0.0)
        {
            CGContextTranslateCTM(quartzContext, objectBox.origin.x, objectBox.origin.y);
            CGContextScaleCTM(quartzContext, objectBox.size.width, objectBox.size.height);
        }
        else
        {
            x1Float = objectBox.origin.x + x1Float*objectBox.size.width;
            y1Float = objectBox.origin.y + y1Float*objectBox.size.height;
            x2Float = objectBox.origin.x + x2Float*objectBox.size.width;
            y2Float = objectBox.origin.y+ y2Float*objectBox.size.height;
        }
    }
    
    CGPoint startPoint = CGPointMake(x1Float, y1Float);
    CGPoint endPoint = CGPointMake(x2Float, y2Float);
    
    
    
    
    NSString* gradientTransformString = [self.attributes objectForKey:@"gradientTransform"];
    if(gradientTransformString.length == 0 || [gradientTransformString isEqualToString:@"rotate(0)"])
    {
        if(y2.length == 0)
        {
            endPoint.y= startPoint.y;
        }
    }
    else
    {
        // this code is not working for anything but a 90 degree rotation. FIX ME
        CGAffineTransform gradientTransform = (gradientTransformString.length == 0)?CGAffineTransformIdentity:SVGTransformToCGAffineTransform(gradientTransformString);
        
        CGRect transformedRect = CGRectMake(startPoint.x, startPoint.y, endPoint.x-startPoint.x, endPoint.y-startPoint.y);
        transformedRect  = CGRectStandardize(transformedRect);
        transformedRect = CGRectApplyAffineTransform(transformedRect, gradientTransform);
        
        startPoint = CGPointMake(transformedRect.origin.x, transformedRect.origin.y);
        endPoint = CGPointMake(transformedRect.origin.x, transformedRect.origin.y+transformedRect.size.height);
    }
    
    CGGradientDrawingOptions options = 0;//kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    CGGradientRef   gradient = [self newGradientRefWithSVGContext:svgContext];
    CGContextDrawLinearGradient(quartzContext,
                                gradient, startPoint, endPoint,
                                options);
    CGGradientRelease(gradient);
    CGContextRestoreGState(quartzContext);
}

@end

@implementation GHRadialGradient
-(void) fillPathToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect)objectBox
{
    NSString* cx = [self.attributes objectForKey:@"cx"];
    NSString* cy = [self.attributes objectForKey:@"cy"];
    NSString* radius = [self.attributes objectForKey:@"r"];
    NSString* fx = [self.attributes objectForKey:@"fx"];
    NSString* fy = [self.attributes objectForKey:@"fy"];
    if([fx length] == 0) fx = cx;
    if([fy length] == 0) fy = cy;
    
    CGFloat     cxFloat = [SVGGradientUtilities extractFractionFromCoordinateString:cx  givenDefault:0.5];
    CGFloat     cyFloat = [SVGGradientUtilities extractFractionFromCoordinateString:cy  givenDefault:0.5];
    CGFloat     radiusFloat = [SVGGradientUtilities extractFractionFromCoordinateString:radius  givenDefault:0.5];
    CGFloat     fxFloat = [SVGGradientUtilities extractFractionFromCoordinateString:fx   givenDefault:0.5];
    CGFloat     fyFloat = [SVGGradientUtilities extractFractionFromCoordinateString:fy   givenDefault:0.5];
   
    CGContextSaveGState(quartzContext);
    if(![self useUserSpace])
    {
        CGContextTranslateCTM(quartzContext, objectBox.origin.x, objectBox.origin.y);
        CGContextScaleCTM(quartzContext, objectBox.size.width, objectBox.size.height);
    }
    
    if(!CGContextIsPathEmpty(quartzContext))
    {
        CGContextClip(quartzContext);
    }
    
    NSString* gradientTransformString = [self.attributes objectForKey:@"gradientTransform"];
    if(gradientTransformString.length)
    {
        CGAffineTransform gradientTransform = SVGTransformToCGAffineTransform(gradientTransformString);
        CGContextConcatCTM(quartzContext, gradientTransform);
    }
    
    CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation;
    CGGradientRef   gradient = [self newGradientRefWithSVGContext:svgContext];
    
    CGContextDrawRadialGradient(quartzContext,
                                gradient, CGPointMake(cxFloat, cyFloat), 0.0,
                                CGPointMake(fxFloat, fyFloat), radiusFloat, options);
    CGGradientRelease(gradient);
    CGContextRestoreGState(quartzContext);
}
 
@end

@implementation GHGradientStop
-(UIColor*) colorWithSVGContext:(id<SVGContext>)svgContext
{
    NSString* opacity = [self.attributes objectForKey:@"stop-opacity"];
    NSString* stopColor = [self.attributes objectForKey:@"stop-color"];
    NSString* styleString = [self.attributes objectForKey:@"style"];
    
    if(styleString.length)
    {
        NSDictionary* newStyles =  [SVGToQuartz dictionaryForStyleAttributeString:styleString];
        if(opacity.length == 0)
        {
            opacity = [newStyles objectForKey:@"stop-opacity"];
        }
        if(stopColor.length == 0)
        {
            stopColor = [newStyles objectForKey:@"stop-color"];
        }
    }
    
    
    UIColor* result = [svgContext colorForSVGColorString:stopColor];
    if([opacity length] && [opacity floatValue] < 1.0)
    {
        result = [result colorWithAlphaComponent:[opacity floatValue]];
    }
    
    return result;
}

-(CGFloat) offset
{
    NSString* offsetString = [self.attributes objectForKey:@"offset"];
    CGFloat result = 0.0;
    if([offsetString hasSuffix:@"%"] && [offsetString length] >=2)
    {
        result = .01f*[[offsetString substringToIndex:[offsetString length]-1] floatValue];
    }
    else
    {
        result = [[self.attributes objectForKey:@"offset"] floatValue];
    }
    
    return result;
}
@end

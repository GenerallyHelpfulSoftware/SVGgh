//
//  GHTextLine.m
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


#import "GHTextLine.h"
#import "GHGlyph.h"
#import "GHRenderable.h"

@interface GHTextLine()
@property(nonatomic, readonly) CTLineRef	lineRef;
@property(nonatomic, readonly) CGAffineTransform transform;
-(void)addGlyphsToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext;
@end;

@implementation GHTextLine
@synthesize fillDescription, strokeDescription, strokeWidth;

-(instancetype) initWithAttributes:(NSDictionary *)theAttributes andTextLine:(CTLineRef)theLineRef
{
	if(nil != (self = [super initWithAttributes:theAttributes]))
	{
        _lineRef = theLineRef;
        if(_lineRef != 0)
        {
            CFRetain(_lineRef);
        }
		NSString*	transformAttribute = [self.attributes objectForKey:@"transform"];
		_transform = SVGTransformToCGAffineTransform(transformAttribute);
        NSString* strokeWidthString = [self.attributes objectForKey:@"stroke-width"];
        if(strokeWidthString.length)
        {
            strokeWidth = strokeWidthString.doubleValue;
        }
        else
        {
            strokeWidth = -1;
        }
	}
	return self;
}

-(NSUInteger)calculatedHash
{
    NSUInteger result = [super calculatedHash];
    if(_lineRef != 0)
    {
        result += CFHash(_lineRef);
    }
    return result;
}

-(BOOL)isEqual:(id)object
{
    BOOL result = object == self;
    
    if(!result && [super isEqual:object])
    {
        GHTextLine* objectAsTextLine = (GHTextLine*)object;
        result = CFEqual(self.lineRef, objectAsTextLine.lineRef);
    }
    
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = CGRectZero;
    if(self.lineRef)
    {
		NSString*	textAnchorString = [self.attributes objectForKey:@"text-anchor"];
        CGFloat ascent = 0.0;
        CGFloat descent = 0.0;
        CGFloat leading = 0.0;
        double lineWidth = CTLineGetTypographicBounds(
                                                      self.lineRef,
                                                      &ascent,
                                                      &descent,
                                                      &leading );
        CGFloat x = 0.0;
        if([textAnchorString isEqualToString:@"middle"])
        {
            x = -lineWidth/2.0;
        }
        if(lineWidth > 0)
        {
            result = CGRectMake(x, -ascent, (CGFloat)lineWidth, ascent+descent); // TODO return the real value
        }
    }
    
    return result;
}

-(CGPathRef) newPath
{
    CGMutablePathRef   letters = CGPathCreateMutable();
    CFArrayRef runArray = CTLineGetGlyphRuns(self.lineRef);
    
    // for each RUN
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
    {
        // Get FONT for this run
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        // for each GLYPH in run
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
        {
            // get Glyph & Glyph-data
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            // Get PATH of outline
            {
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
    }
    
    NSDictionary* myAttributes = self.attributes;
    
    NSNumber*	xOffset = [myAttributes objectForKey:@"x"];
    NSNumber*	yOffset = [myAttributes objectForKey:@"y"];
    NSNumber*	deltaX = [myAttributes objectForKey:@"dx"];
    NSNumber*	deltaY = [myAttributes objectForKey:@"dy"];
    NSNumber*	rotation = [myAttributes objectForKey:@"rotate"];
    CGAffineTransform	affineTransform = CGAffineTransformMakeScale(1.0, -1.0);
    
    affineTransform = CGAffineTransformTranslate(affineTransform, [xOffset floatValue], -[yOffset floatValue]);
    affineTransform = CGAffineTransformTranslate(affineTransform, [deltaX floatValue], -[deltaY floatValue]);
    affineTransform = CGAffineTransformRotate(affineTransform, [rotation floatValue]);
    
    CGPathRef result = CGPathCreateCopyByTransformingPath(letters,
                                                        &affineTransform);
    
    
    CGPathRelease(letters);
    
    return result;
}

-(CGAffineTransform) glyphTransform
{
    NSDictionary* myAttributes = self.attributes;
    
    NSNumber*	xOffset = [myAttributes objectForKey:@"x"];
    NSNumber*	yOffset = [myAttributes objectForKey:@"y"];
    NSNumber*	deltaX = [myAttributes objectForKey:@"dx"];
    NSNumber*	deltaY = [myAttributes objectForKey:@"dy"];
    NSNumber*	rotation = [myAttributes objectForKey:@"rotate"];
    
    
    CGAffineTransform result = self.transform;
    result = CGAffineTransformTranslate(result, [deltaX floatValue], [deltaY floatValue]);
    result = CGAffineTransformRotate(result, [rotation floatValue]);
    
    CGFloat	textPositionX = [xOffset floatValue];
    CGFloat	textPositionY = [yOffset floatValue];
    NSString*	textAnchorString = [myAttributes objectForKey:@"text-anchor"];
    if([textAnchorString length])
    {
        
        double lineWidth = CTLineGetTypographicBounds(self.lineRef,NULL,NULL,NULL);
        if([textAnchorString isEqualToString:@"start"])
        {
        }
        else if([textAnchorString isEqualToString:@"middle"])
        {
            textPositionX -= lineWidth/2.0;
        }
        else if([textAnchorString isEqualToString:@"end"])
        {
            textPositionX -= lineWidth;
        }
    }
    
    result = CGAffineTransformTranslate(result, textPositionX, textPositionY);
    
    result = CGAffineTransformScale(result, 1.0, -1.0);
    
    return result;
}

-(void)addGlyphsToArray:(NSMutableArray*)glyphList  withSVGContext:(id<SVGContext>)svgContext
{
    CTLineRef myLineRef = self.lineRef;
    if(myLineRef != 0)
    {
        CFArrayRef runArray = CTLineGetGlyphRuns(myLineRef);
        CGAffineTransform   glyphTransform = [self glyphTransform];
        CGPoint             lastPoint = CGPointZero;
        CGPoint             startOffset = CGPointZero;
        if(glyphList.count)
        {
            GHGlyph* previousGlyph = [glyphList lastObject];
            startOffset = lastPoint = previousGlyph.offset;
            startOffset.x += previousGlyph.width;
        }
        
        NSNumber* deltaY = [self.attributes objectForKey:@"dy"];
        NSNumber* deltaX = [self.attributes objectForKey:@"dx"];
        
        CGPoint manualOffset = CGPointZero;
        if(deltaX != nil || deltaY != nil)
        {
            manualOffset = CGPointMake([deltaX floatValue], [deltaY floatValue]);
        }
        
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
        {
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
            CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            CFDictionaryRef textAttributes = CTRunGetAttributes(run);
            CFIndex glyphCount = CTRunGetGlyphCount(run);
            
            
            CFRange wholeGlyphRnge = CFRangeMake(0, glyphCount);
            
            NSMutableData* glyphs = [NSMutableData dataWithCapacity:sizeof(CGGlyph)*glyphCount];
            CGGlyph* rawGlyphPtr = (CGGlyph*)glyphs.mutableBytes;
            CTRunGetGlyphs(run, wholeGlyphRnge, rawGlyphPtr);
            
            for (CFIndex glyphIndex = 0; glyphIndex < glyphCount; glyphIndex++)
            {
                CFRange thisGlyphRange = CFRangeMake(glyphIndex, 1);
                CGGlyph glyph = rawGlyphPtr[glyphIndex];
                CGPoint position;
                CTRunGetPositions(run, thisGlyphRange, &position);
                
                glyphTransform = CGAffineTransformTranslate(glyphTransform, position.x-lastPoint.x, position.y-lastPoint.y);
                
                position.x += startOffset.x;
                position.y += startOffset.y;
                
                lastPoint = position;
                
                position.x += manualOffset.x;
                position.y += manualOffset.y;
                CFRange runRange = CFRangeMake(glyphIndex, 1);
                double width = CTRunGetTypographicBounds(run,
                                                         runRange,
                                                         NULL,
                                                         NULL,
                                                         NULL);
                CGRect runBox = CTRunGetImageBounds(run, nil, thisGlyphRange);
                
                GHGlyph* aGlyph = [[GHGlyph alloc] initWithDictionary:self.attributes
                                                   textAttributes:[(__bridge NSDictionary*)textAttributes copy]
                                                    font:runFont glyph:glyph
                                                    transform:glyphTransform
                                                    offset:position
                                                    runBox:runBox
                                                    andWidth:(CGFloat)width];
                [glyphList addObject:aGlyph];
                
            }
        }
    }
}

-(void)addGlyphsToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    CTLineRef myLineRef = self.lineRef;
    if(myLineRef != 0)
    {
        CFArrayRef runArray = CTLineGetGlyphRuns(myLineRef);
        CGMutablePathRef    glyphPaths = CGPathCreateMutable();
        CGAffineTransform   glyphTransform = [self glyphTransform];
        CGPoint             lastPoint = CGPointZero;
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
        {
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
            CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            
            for (CFIndex glyphIndex = 0; glyphIndex < CTRunGetGlyphCount(run); glyphIndex++)
            {
                CFRange thisGlyphRange = CFRangeMake(glyphIndex, 1);
                CGGlyph glyph;
                CGPoint position;
                CTRunGetGlyphs(run, thisGlyphRange, &glyph);
                CTRunGetPositions(run, thisGlyphRange, &position);
                
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                glyphTransform = CGAffineTransformTranslate(glyphTransform, position.x-lastPoint.x, position.y-lastPoint.y);
                CGPathAddPath(glyphPaths, &glyphTransform, letter);
                CGPathRelease(letter);
                lastPoint = position;
            }
        }
        CGContextAddPath(quartzContext, glyphPaths);
        CGPathRelease(glyphPaths);
    }
}


-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)theContext
{
	if(self.lineRef)
	{
        NSDictionary* myAttributes = self.attributes;
        
		NSNumber*	xOffset = [myAttributes objectForKey:@"x"];
		NSNumber*	yOffset = [myAttributes objectForKey:@"y"];
		NSNumber*	deltaX = [myAttributes objectForKey:@"dx"];
		NSNumber*	deltaY = [myAttributes objectForKey:@"dy"];
		NSNumber*	rotation = [myAttributes objectForKey:@"rotate"];
		
		CGAffineTransform	affineTransform = CGAffineTransformMakeScale(1.0, -1.0);
		
		CGContextSetTextMatrix(quartzContext, affineTransform);
		affineTransform = CGAffineTransformIdentity;//self.transform; // this wasn't rendering right from SVGText
		affineTransform = CGAffineTransformTranslate(affineTransform, [deltaX floatValue], [deltaY floatValue]);
		affineTransform = CGAffineTransformRotate(affineTransform, [rotation floatValue]);
		CGContextConcatCTM(quartzContext, affineTransform);
		
		CGFloat	textPositionX = [xOffset floatValue];
		CGFloat	textPositionY = [yOffset floatValue];
        
		NSString*	textAnchorString = [myAttributes objectForKey:@"text-anchor"];
		if([textAnchorString length])
		{
			
			double lineWidth = CTLineGetTypographicBounds(self.lineRef,NULL,NULL,NULL);
			if([textAnchorString isEqualToString:@"start"])
			{
			}
			else if([textAnchorString isEqualToString:@"middle"])
			{
				textPositionX -= lineWidth/2.0;
			}
			else if([textAnchorString isEqualToString:@"end"])
			{
				textPositionX -= lineWidth;
			}
		}
		
		CGContextSetTextPosition(quartzContext, textPositionX, textPositionY);
		CTLineDraw(self.lineRef,quartzContext);
	}
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kFontGlyphClippingType;
    return result;
}

-(void) dealloc
{
    if(_lineRef)
    {
        CFRelease(_lineRef);
    }
}

@end

//
//  Text.m
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
//  Created by Glenn Howes on 5/19/11.


#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreText;
#else
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#endif

#import "GHText.h"
#import "GHGradient.h"
#import "SVGPathGenerator.h"
#import "SVGUtilities.h"
#import "SVGTextUtilities.h"
#import "GHPathUtilities.h"
#import "GHGlyph.h"
#import "GHTextLine.h"




@interface TextPath : GHText

@end


@interface GHText()
@property(nonatomic, readonly)              CTFontDescriptorRef fontDescriptor;
@property(nonatomic, readonly)              CTFontRef			fontRef;
@property(strong, nonatomic, readonly)      NSArray*			children;
@property(strong, nonatomic, readonly)      NSArray*			contents; // svg version of children
-(void) setupFontDescriptorWithBaseDescriptor:(CTFontDescriptorRef)baseDescriptor andBaseFont:(CTFontRef)baseFont;
@end

@implementation GHText
@synthesize fontDescriptor=_fontDescriptor, fontRef=_fontRef, children=_children, contents=_contents;
@synthesize fillDescription=_fillDescription, strokeDescription=_strokeDescription;
@synthesize strokeWidth=_strokeWidth;

-(BOOL) cleanLineEndings
{
    BOOL result = YES;
    
    return result;
}
-(CTFontDescriptorRef) fontDescriptor
{
	if(_fontDescriptor == 0)
	{
		_fontDescriptor = [SVGTextUtilities newFontDescriptorFromAttributes:self.attributes baseDescriptor:0];
	}
	return _fontDescriptor;
}

-(CTFontRef) fontRef
{
	if(_fontRef == 0)
	{
        _fontRef = [SVGTextUtilities newFontRefFromFontDescriptor:self.fontDescriptor];
	}
	return _fontRef;
}

-(NSArray*)children
{
	if(_children == nil)
	{
        NSCharacterSet* notSpace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
		NSMutableArray* mutableResult = [[NSMutableArray alloc] initWithCapacity:[self.contents count]];
		CTFontRef myFontRef = self.fontRef;
		CTFontDescriptorRef	myFontDescription = self.fontDescriptor;
		NSMutableAttributedString*	currentString = [[NSMutableAttributedString alloc] init];
		NSArray* contentsToUse = self.contents;
		NSDictionary* defaultDefinition = [NSDictionary dictionaryWithObject:self.attributes forKey:kAttributesElementName];
		NSDictionary*	lastDefinition = defaultDefinition;
		if([contentsToUse count] == 1 
		   && [[contentsToUse lastObject] isKindOfClass:[NSDictionary class]]
		   && [[[contentsToUse lastObject] objectForKey:kContentsElementName] count] > 0)
		{
			contentsToUse = [[contentsToUse lastObject] objectForKey:kContentsElementName];
		}
		
		for(id aChild in contentsToUse)
		{
			if([aChild isKindOfClass:[NSDictionary class]])
			{
				NSDictionary* aDefinition = (NSDictionary*)aChild;
				NSString*	elementName = [aDefinition objectForKey:kElementName];
                
                
				if([elementName isEqualToString:@"tspan"])
				{
					NSDictionary* tspanAttributes = [aDefinition objectForKey:kAttributesElementName];
					NSString*	text = [aDefinition objectForKey:kElementText];
                    if([self cleanLineEndings])
                    {
                        text = [SVGTextUtilities cleanXMLText:text];
                    }
                     NSRange firstNonWhite = [text rangeOfCharacterFromSet:notSpace];
                    
					if(firstNonWhite.location != NSNotFound)
					{
						NSAttributedString* spansAttributedString = [SVGTextUtilities attributedStringFromString:text
                                                                                SVGStyleAttributes:tspanAttributes
                                                                                baseFont:myFontRef
                                                                                baseFontDescriptor:myFontDescription
                                                                               includeParagraphStyle:NO];
						if([tspanAttributes objectForKey:@"transform"] != nil
						   || [tspanAttributes objectForKey:@"x"] != nil
						   || [tspanAttributes objectForKey:@"dx"] != nil
						   || [tspanAttributes objectForKey:@"y"] != nil
						   || [tspanAttributes objectForKey:@"dy"] != nil
						   || [tspanAttributes objectForKey:@"rotate"] != nil)
						{ // need a new line
							if([currentString length])
							{
								CTLineRef lineRef = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) currentString);
								if(lineRef != 0)
								{
                                    NSDictionary* theAttributes = [lastDefinition objectForKey:kAttributesElementName];
									GHTextLine* aLine = [[GHTextLine alloc] initWithAttributes:theAttributes andTextLine:lineRef];
									CFRelease(lineRef);
									[mutableResult addObject:aLine];
								}
							}	
							currentString = [[NSMutableAttributedString alloc] initWithAttributedString:spansAttributedString];
                            lastDefinition = aDefinition;
							
						}
						else 
						{// append to old line, just a change in style
							
							[currentString appendAttributedString:spansAttributedString];
						}
					}
					
				}
                else if([elementName isEqualToString:@"textPath"])
                {
                    if([currentString length])
                    {
                        CTLineRef lineRef = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) currentString);
                        if(lineRef != 0)
                        {
                            NSDictionary* theAttributes = [lastDefinition objectForKey:kAttributesElementName];
                            GHTextLine* aLine = [[GHTextLine alloc] initWithAttributes:theAttributes andTextLine:lineRef];
                            CFRelease(lineRef);
                            [mutableResult addObject:aLine];
                            lastDefinition = aDefinition;
                        }
                    }
                    
                    TextPath* aTextPath = [[TextPath alloc] initWithDictionary:aChild];
                    [aTextPath setupFontDescriptorWithBaseDescriptor:myFontDescription andBaseFont:myFontRef];
                    [mutableResult addObject:aTextPath];
                }
			}
			else if([aChild isKindOfClass:[NSString class]])
			{
                NSString* childAsString = aChild;
                if([self cleanLineEndings])
                {
                    childAsString = [SVGTextUtilities cleanXMLText:childAsString];
                }
                
                NSRange firstNonWhite = [childAsString rangeOfCharacterFromSet:notSpace];
                
                if(childAsString.length && firstNonWhite.location != NSNotFound)
                {
                    NSAttributedString* spansAttributedString = [SVGTextUtilities attributedStringFromString:childAsString
                                                                       nonFontSVGStyleAttributes:self.attributes
                                                                                        baseFont:myFontRef
                                                                              baseFontDescriptor:myFontDescription
                                                                            includeParagraphStyle:NO];
                    
                    
                    NSDictionary* lastAttributes = [lastDefinition objectForKey:kAttributesElementName];
                    if(lastDefinition != defaultDefinition
                       && ([lastAttributes objectForKey:@"transform"] != nil
                           || [lastAttributes objectForKey:@"x"] != nil
                           || [lastAttributes objectForKey:@"dx"] != nil
                           || [lastAttributes objectForKey:@"y"] != nil
                           || [lastAttributes objectForKey:@"dy"] != nil
                           || [lastAttributes objectForKey:@"rotate"] != nil))
                    {// need a new line
                        if([currentString length])
                        {
                            CTLineRef lineRef = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) currentString);
                            if(lineRef != 0)
                            {
                                NSDictionary* theAttributes = [lastDefinition objectForKey:kAttributesElementName];
                                GHTextLine* aLine = [[GHTextLine alloc] initWithAttributes:theAttributes andTextLine:lineRef];
                                CFRelease(lineRef);
                                [mutableResult addObject:aLine];
                            }
                        }	
                        currentString = [[NSMutableAttributedString alloc] initWithAttributedString:spansAttributedString];
                        
                    }
                    else
                    {
                        [currentString appendAttributedString:spansAttributedString];
                    }
                    lastDefinition = defaultDefinition;
                }
			}
		}
		if([currentString length])
		{
			CTLineRef lineRef = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) currentString);
			if(lineRef != 0)
			{
                NSDictionary* theAttributes = [lastDefinition objectForKey:kAttributesElementName];
                GHTextLine* aLine = [[GHTextLine alloc] initWithAttributes:theAttributes andTextLine:lineRef];
				CFRelease(lineRef);
				[mutableResult addObject:aLine];
			}
		}	
		_children = [mutableResult copy];
	}
	return _children;
}

-(void)addGlyphsToArray:(NSMutableArray*)glyphList  withSVGContext:(id<SVGContext>)svgContext
{
    NSArray* myChildren = self.children;
    for(NSObject<GHPathDescription, GHGlyphMaker>* aChild in myChildren)
    {
        [aChild addGlyphsToArray:glyphList withSVGContext:svgContext];
    }
}

-(instancetype) initWithDictionary:(NSDictionary*)theDefinition
{
	if(nil != (self = [super initWithDictionary:theDefinition]))
	{
		_contents = [theDefinition objectForKey:kContentsElementName];
        _fillDescription = [SVGToQuartz valueForStyleAttribute:@"fill" fromDefinition:theDefinition];
        _strokeDescription = [SVGToQuartz valueForStyleAttribute:@"stroke" fromDefinition:theDefinition];
        
        NSString* strokeWidthDescripion = [SVGToQuartz valueForStyleAttribute:@"stroke-width" fromDefinition:theDefinition];
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
    result += [self.contents hash];
    
    return result;
}

-(NSString*) entityName
{
    return @"text";
}


-(BOOL)isEqual:(id)object
{
    BOOL result = object == self;
    
    if(!result && [super isEqual:object])
    {
        GHText* objectAsText = (GHText*)object;
        result = [self.contents isEqual:objectAsText.contents] && [self.children isEqual:objectAsText.children];
    }
    
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    CGRect myBox = [self getBoundingBoxWithSVGContext:svgContext];
    NSString* fillString = [self.attributes objectForKey:@"fill"];
    GHGradient* defaultGradientFillToUse = nil;
    UIColor*  defaultFillColorToUse = [svgContext currentColor];
    GHGradient* defaultGradientStrokeToUse = nil;
    UIColor*  defaultStrokeColorToUse = nil;
    CGFloat   defaultStrokeWidthToUse = -1;
    
    if([fillString isEqualToString:@"none"])
    {
        defaultFillColorToUse = nil;
    }
    else if(IsStringURL(fillString))
    {
        id aColor = [svgContext objectAtURL:fillString];
        if([aColor isKindOfClass:[GHGradient class]])
        {
            defaultGradientFillToUse = aColor;
        }
        else if([aColor isKindOfClass:[GHSolidColor class]])
        {
            defaultFillColorToUse = [(GHSolidColor*)aColor asColorWithSVGContext:svgContext];
        }
    }
    else if([fillString length])
    {
        defaultFillColorToUse = [svgContext colorForSVGColorString:fillString];
    }
    else
    {
        defaultFillColorToUse = [UIColor blackColor];
    }
    
    NSString* strokeString = [self.attributes objectForKey:@"stroke"];
    if([strokeString isEqualToString:@"none"])
    {
    }
    else if(IsStringURL(strokeString))
    {
        id aColor = [svgContext objectAtURL:strokeString];
        if([aColor isKindOfClass:[GHGradient class]])
        {
            defaultGradientStrokeToUse = aColor;
        }
        else if([aColor isKindOfClass:[GHSolidColor class]])
        {
            defaultStrokeColorToUse = [(GHSolidColor*)aColor asColorWithSVGContext:svgContext];
        }
    }
    else if([strokeString length])
    {
        defaultStrokeColorToUse = [svgContext colorForSVGColorString:strokeString];
    }
    
    NSString* strokeWidthDescripion = [self.attributes objectForKey:@"stroke-width"];
    if([strokeWidthDescripion length])
    {
        defaultStrokeWidthToUse = [strokeWidthDescripion floatValue];
    }
    
    UIColor* savedContextColor = [svgContext currentColor];
    
    CGContextSaveGState(quartzContext);
    CGContextConcatCTM(quartzContext, self.transform);
    for(NSObject<GHPathDescription, GHGlyphMaker>* aChild in self.children)
    {
        GHGradient* gradientFillToUse = defaultGradientFillToUse;
        UIColor*  fillColorToUse = defaultFillColorToUse;
        GHGradient* gradientStrokeToUse = defaultGradientStrokeToUse;
        UIColor*  strokeColorToUse = defaultStrokeColorToUse;
        CGFloat   strokeWidthToUse = defaultStrokeWidthToUse;
        
        
        if([aChild.fillDescription length])
        {
            if([aChild.fillDescription isEqualToString:@"inherited"])
            {
                
            }
            else if([aChild.fillDescription isEqualToString:@"none"])
            {
                gradientFillToUse = nil;
                fillColorToUse = nil;
            }
            else if(IsStringURL(aChild.fillDescription))
            {
                gradientFillToUse = nil;
                fillColorToUse = nil;
                id aColor = [svgContext objectAtURL:aChild.fillDescription];
                if([aColor isKindOfClass:[GHGradient class]])
                {
                    gradientFillToUse = aColor;
                }
                else if([aColor isKindOfClass:[GHSolidColor class]])
                {
                    fillColorToUse = [(GHSolidColor*)aColor asColorWithSVGContext:svgContext];
                }
            }
            else
            {
                gradientFillToUse = nil;
                fillColorToUse = [svgContext colorForSVGColorString:aChild.fillDescription];
            }
        }
        if([aChild.strokeDescription length])
        {
            if([aChild.strokeDescription isEqualToString:@"inherited"])
            {
                
            }
            else if([aChild.strokeDescription isEqualToString:@"none"])
            {
                gradientStrokeToUse = nil;
                strokeColorToUse = nil;
            }
            else if(IsStringURL(aChild.strokeDescription))
            {
                gradientStrokeToUse = nil;
                strokeColorToUse = nil;
                id aColor = [svgContext objectAtURL:aChild.strokeDescription];
                if([aColor isKindOfClass:[GHGradient class]])
                {
                    gradientStrokeToUse = aColor;
                }
                else if([aColor isKindOfClass:[GHSolidColor class]])
                {
                    strokeColorToUse = [(GHSolidColor*)aColor asColorWithSVGContext:svgContext];
                }
            }
            else if([aChild.strokeDescription length])
            {
                gradientStrokeToUse = nil;
                strokeColorToUse = [svgContext colorForSVGColorString:aChild.strokeDescription];
            }

        }
        if(aChild.strokeWidth > 0.0)
        {
            strokeWidthToUse = aChild.strokeWidth;
        }
        if(strokeWidthToUse < 0)
        {
            strokeWidthToUse = 3.0;
        }
        
        [svgContext setCurrentColor:savedContextColor];
        if(fillColorToUse != nil)
        {
            [svgContext setCurrentColor:fillColorToUse];
        }
        if(gradientFillToUse != nil)
        {
            CGContextSaveGState(quartzContext);
            CGContextSetTextDrawingMode(quartzContext, kCGTextClip);
            
            CGPathRef aPath = [aChild newPath];
            CGRect myBox = CGPathGetPathBoundingBox(aPath);
            if(!CGRectIsEmpty(myBox))
            {
                CGContextClipToRect(quartzContext, myBox);
                CGContextAddPath(quartzContext, aPath);
                [gradientFillToUse fillPathToContext:quartzContext withSVGContext:svgContext objectBoundingBox:myBox];
            }
            
            CGContextSetTextDrawingMode(quartzContext, kCGTextFill);
            CGPathRelease(aPath);
            CGContextRestoreGState(quartzContext);
        }
        else if(fillColorToUse != nil)
        {   CGContextSaveGState(quartzContext);
            
            CGContextSetFillColorWithColor(quartzContext, fillColorToUse.CGColor);
            CGContextSetStrokeColorWithColor(quartzContext, fillColorToUse.CGColor);
            [aChild renderIntoContext:quartzContext withSVGContext:svgContext];
            
            CGContextRestoreGState(quartzContext);
        }
        
        if(strokeWidthToUse > 0)
        {
            if(gradientStrokeToUse != nil)
            {
                CGContextSaveGState(quartzContext);
                CGContextSetTextDrawingMode(quartzContext, kCGTextStrokeClip);
                CGContextSetLineWidth(quartzContext, strokeWidthToUse);
                [aChild addGlyphsToContext:quartzContext withSVGContext:svgContext];
                 CGContextReplacePathWithStrokedPath(quartzContext);
                CGContextClip(quartzContext);
                [gradientStrokeToUse fillPathToContext:quartzContext withSVGContext:svgContext objectBoundingBox:myBox];
                CGContextSetTextDrawingMode(quartzContext, kCGTextFill);
                CGContextRestoreGState(quartzContext);
            }
            else if(strokeColorToUse != nil)
            {
                CGContextSaveGState(quartzContext);
                CGContextSetStrokeColorWithColor(quartzContext, strokeColorToUse.CGColor);
                CGContextSetTextDrawingMode(quartzContext, kCGTextStroke);
                [aChild renderIntoContext:quartzContext withSVGContext:svgContext];
                CGContextRestoreGState(quartzContext);
                
            }
        }
    }
    [svgContext setCurrentColor:savedContextColor];
    
    CGContextRestoreGState(quartzContext);
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = CGRectZero;
    for(NSObject<GHPathDescription, GHGlyphMaker>* aChild in self.children)
	{
        if([aChild respondsToSelector:@selector(getBoundingBoxWithSVGContext:)])
        {
            CGRect childRect = [(GHTextLine*)aChild getBoundingBoxWithSVGContext:svgContext];
            if(!CGRectIsNull(result) && !CGRectIsNull(childRect))
            {
                result = CGRectUnion(result, childRect);
            }
            else if(!CGRectIsNull(childRect))
            {
                result = childRect;
            }
        }
	}
    return result;
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kFontGlyphClippingType;
    return result;
}

-(void) setupFontDescriptorWithBaseDescriptor:(CTFontDescriptorRef)baseDescriptor andBaseFont:(CTFontRef)baseFont
{
	NSDictionary* myAttributes = self.attributes;
	NSString*	styleString = [myAttributes objectForKey:@"style"];
	if([styleString length] || baseDescriptor == 0)
	{
		_fontDescriptor = [SVGTextUtilities newFontDescriptorFromAttributes:myAttributes baseDescriptor:baseDescriptor];
	}
	else
	{
		CFRetain(baseDescriptor);
		_fontDescriptor = baseDescriptor;
	}
	
	if(baseDescriptor == self.fontDescriptor && baseFont != 0)
	{
		CFRetain(baseFont);
		_fontRef = baseFont;
	}
}

-(void) dealloc
{
	if(_fontRef != 0)
	{
		CFRelease(_fontRef);
	}
	if(_fontDescriptor !=0)
	{
		CFRelease(_fontDescriptor);
	}
}

@end




@interface GHTextArea ()
{
    CTFramesetterRef    frameSetter;
    CTFrameRef          frame;
}
@property(nonatomic, readonly) CTFramesetterRef frameSetter;
@property(nonatomic, readonly) CTFrameRef       frame;
@property(nonatomic, readonly) CGSize           size;
@property(nonatomic, readonly) CGRect           box;
@property(nonatomic, readonly) NSDictionary* definition;
@end

@implementation GHTextArea
@synthesize text = _text;
-(instancetype) initWithDictionary:(NSDictionary*)theDefinition
{
    if(nil != (self = [super initWithDictionary:theDefinition]))
    {
        _definition = theDefinition;
    }
    return self;
}

+(NSMutableAttributedString*) attributedStringFromTSpan:(NSDictionary*)aTSpanDefinition
                                               optimize:(BOOL)optimize
                                              preserveLineEndings:(BOOL)preserveXMLlineEndings
                                                attributes:(NSDictionary*)activeAttributes
                                                baseFont:(CTFontRef)baseFont
                                               baseFontDescriptor:(CTFontDescriptorRef)myFontDescription
{
    NSMutableAttributedString* result = [[NSMutableAttributedString alloc]init];
    if(optimize)
    {
        [result beginEditing];
    }
    NSString* rawText = [aTSpanDefinition objectForKey:kElementText];
    rawText = [rawText stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\u2029"];
    rawText = [rawText stringByReplacingOccurrencesOfString:@"\n" withString:@"\u2029"];
    NSArray* mySubElements = [aTSpanDefinition objectForKey:kContentsElementName];
    NSMutableArray* brokenDownElements = [[NSMutableArray alloc] initWithCapacity:[mySubElements count]*2];
    NSUInteger  stringLocation = 0;
    
    for(NSDictionary* aSubElement in mySubElements)
    {
        if([aSubElement isKindOfClass:[NSDictionary class]])
        {
            NSString* elementName = [aSubElement objectForKey:kElementName];
            NSNumber* indexIn = [aSubElement objectForKey:kLengthIntoParentsContents];
            NSUInteger indexInValue = [indexIn unsignedIntegerValue];
            if([elementName isEqualToString:@"tbreak"])
            {
                if(indexInValue > stringLocation)
                {
                    NSString* subString = [rawText substringWithRange:NSMakeRange(stringLocation, indexInValue-stringLocation)];
                    [brokenDownElements addObject:subString];
                    stringLocation = indexInValue;
                }
                [brokenDownElements addObject:aSubElement];
            }
            else if([elementName isEqualToString:@"tspan"])
            {
                if(indexInValue > stringLocation)
                {
                    NSString* subString = [rawText substringWithRange:NSMakeRange(stringLocation, indexInValue-stringLocation)];
                    [brokenDownElements addObject:subString];
                    stringLocation = indexInValue;
                }
                [brokenDownElements addObject:aSubElement];
            }
        }
    }
    
    if(stringLocation < ([rawText length]-1))
    {
        NSString* subString = [rawText substringWithRange:NSMakeRange(stringLocation, [rawText length]-stringLocation)];
        if(subString != nil)
        {
            [brokenDownElements addObject:subString];
        }
    }
    
    BOOL lastElementWasLineEnding = NO;
    for(id anElement in brokenDownElements)
    {
        if([anElement isKindOfClass:[NSString class]])
        {
            NSString* stringToAppend = anElement;
            if(!preserveXMLlineEndings &&[stringToAppend isEqualToString:@"\n"])
            {
                if(!lastElementWasLineEnding)
                {
                    stringToAppend = @" ";
                    lastElementWasLineEnding = YES;
                    
                    NSAttributedString* aStringAttributed = [SVGTextUtilities attributedStringFromString:stringToAppend
                                                                   SVGStyleAttributes:activeAttributes
                                                                    baseFont:baseFont
                                                                          baseFontDescriptor:myFontDescription
                                                                       includeParagraphStyle:YES];
                 
                    [result appendAttributedString:aStringAttributed];
                }
                
            }
            else
            {
                if(!preserveXMLlineEndings)
                {
                    lastElementWasLineEnding = [stringToAppend hasSuffix:@"\n"];
                    NSArray* stringsBrokenUpByNewLines = [stringToAppend componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    for(NSString* aSubstring in stringsBrokenUpByNewLines)
                    {
                        NSString* aString = [aSubstring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if(aString.length)
                        {
                            aString = [aString stringByAppendingString:@" "];
                        
                            NSAttributedString* aStringAttributed = [SVGTextUtilities attributedStringFromString:aString
                                                                           SVGStyleAttributes:activeAttributes
                                                                                            baseFont:baseFont
                                                                                  baseFontDescriptor:myFontDescription
                                                                               includeParagraphStyle:YES];
                            [result appendAttributedString:aStringAttributed];
                        
                        }
                    }
                }
                else
                {
                    NSAttributedString* aStringAttributed = [SVGTextUtilities attributedStringFromString:stringToAppend
                                                                   SVGStyleAttributes:activeAttributes
                                                                                    baseFont:baseFont
                                                                          baseFontDescriptor:myFontDescription
                                                                       includeParagraphStyle:YES];
                    [result appendAttributedString:aStringAttributed];
                }
            }
        }
        else if([anElement isKindOfClass:[NSDictionary class]])
        {
            
            NSString* elementName = [anElement objectForKey:kElementName];
            if([elementName isEqualToString:@"tbreak"])
            {
                NSAttributedString* aStringAttributed = [SVGTextUtilities attributedStringFromString:@"\n"
                                                               SVGStyleAttributes:activeAttributes
                                                                                baseFont:baseFont
                                                                      baseFontDescriptor:myFontDescription
                                                                   includeParagraphStyle:YES];
                [result appendAttributedString:aStringAttributed];
            }
            else if([elementName isEqualToString:@"tspan"])
            {
                NSMutableDictionary* spansAttributes = [activeAttributes mutableCopy];
                NSDictionary* elementsAttributes = [anElement objectForKey:kAttributesElementName];
                if([elementsAttributes count])
                {
                    [spansAttributes setValuesForKeysWithDictionary:elementsAttributes];
                }
                NSMutableAttributedString* tSpansAttributedString = [GHTextArea attributedStringFromTSpan:anElement
                                                                                               optimize:NO
                                                                             preserveLineEndings:preserveXMLlineEndings
                                                                                            attributes:spansAttributes
                                                                                        baseFont:baseFont
                                                                              baseFontDescriptor:myFontDescription];
                [result appendAttributedString:tSpansAttributedString];
            }
        }
    }
    if(optimize)
    {
        [result endEditing];
    }
    return result;
}

-(NSString*) entityName
{
    return @"textArea";
}


-(NSUInteger)calculatedHash
{
    NSUInteger result = [super calculatedHash];
    result += [self.definition hash];
    
    return result;
}

-(BOOL)isEqual:(id)object
{
    BOOL result = object == self;
    
    if(!result && [super isEqual:object])
    {
        GHTextArea* objectAsText = (GHTextArea*)object;
        result = [self.definition isEqual:objectAsText.definition];
    }
    
    return result;
}

-(BOOL) cleanLineEndings
{
    NSDictionary* myAttributes = self.attributes;
    NSString* linePreservation = [myAttributes objectForKey:@"xml:space"];
    
    BOOL result = ![linePreservation isEqualToString:@"preserve"];
    return result;
}


-(NSAttributedString*)text
{
    NSAttributedString* result = _text;
    if(result == nil)
    {
		CTFontDescriptorRef	myFontDescription = self.fontDescriptor;
        CTFontRef myFontRef = self.fontRef;
        NSMutableAttributedString* mutableResult = [GHTextArea attributedStringFromTSpan:_definition
                                                                              optimize:YES
                                                                   preserveLineEndings:![self cleanLineEndings]
                                                                    attributes:self.attributes
                                                                    baseFont:myFontRef
                                                                    baseFontDescriptor:myFontDescription];
        result = _text = [mutableResult copy];
        
    }
    
    return result;
}

-(CTFramesetterRef) frameSetter
{
    CTFramesetterRef result = frameSetter;
    if(result == 0)
    {
        result = frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef) self.text);
    }
    return result;
}

-(CGSize) size
{
    CGSize result = CGSizeZero;
    CGFloat height = CGFLOAT_MAX;
    CGFloat width = CGFLOAT_MAX;
    
    NSString* heightAttribute = [self.attributes objectForKey:@"height"];
    if(heightAttribute.length && ![heightAttribute isEqualToString:@"auto"])
    {
        height = heightAttribute.floatValue;
    }
    
    NSString* widthAttribute = [self.attributes objectForKey:@"width"];
    if(widthAttribute.length && ![widthAttribute isEqualToString:@"auto"])
    {
        width = widthAttribute.floatValue;
    }
    
    result = CGSizeMake(width, height);
    if(height == CGFLOAT_MAX || width == CGFLOAT_MAX)
    {
        CFRange stringThatFitsRange;
        result =  CTFramesetterSuggestFrameSizeWithConstraints(self.frameSetter,
                                                            CFRangeMake(0, (CFIndex)self.text.string.length),
                                                            0,
                                                            result,
                                                            &stringThatFitsRange);
    }
    return result;
}

-(CTFrameRef) frame
{
    CTFrameRef result = frame;
    if(result == 0)
    {
        CGSize mySize = self.size;
        CGRect pathRect = CGRectMake(0, 0, mySize.width, mySize.height);
        CGPathRef path = CGPathCreateWithRect(pathRect, nil);
        result = frame = CTFramesetterCreateFrame(self.frameSetter,
                                            CFRangeMake(0, 0),
                                            path,0);
        CGPathRelease(path);
    }
    
    return result;
}

-(NSArray*)children
{
    return nil;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    if(self.frame)
    {
        CGRect myBox = self.box;
        CGContextSaveGState(quartzContext);
        NSString* fillString = [self valueForStyleAttribute:@"fill" withSVGContext:svgContext];
        UIColor* textColor = nil ;
		if(fillString.length)
        {
            textColor = [svgContext colorForSVGColorString:fillString];
        }
		if(textColor == nil)
		{
            textColor = [UIColor blackColor];
        }
        if(textColor != nil)
        {
            CGContextSetFillColorWithColor(quartzContext, textColor.CGColor);
        }
        
        CGContextConcatCTM(quartzContext, self.transform);
        CGContextSetTextMatrix (quartzContext, CGAffineTransformIdentity);
        CGContextTranslateCTM(quartzContext, myBox.origin.x, myBox.origin.y+myBox.size.height);
        CGContextScaleCTM(quartzContext, 1.0, -1.0);
        
        CGSize mySize = self.size;
        NSString* verticalAlignement = [self.attributes objectForKey:@"display-align"];
        if([verticalAlignement length] && ![verticalAlignement isEqualToString:@"auto"] && ![verticalAlignement isEqualToString:@"before"])
        {
            CFRange stringThatFitsRange;
            CGSize neededSize = CTFramesetterSuggestFrameSizeWithConstraints(self.frameSetter,
                                                               CFRangeMake(0, (CFIndex)self.text.string.length),
                                                               0,
                                                               mySize,
                                                               &stringThatFitsRange);
            if(neededSize.height < mySize.height)
            {
                if([verticalAlignement isEqualToString:@"center"])
                {
                    CGContextTranslateCTM(quartzContext, 0, -(mySize.height-neededSize.height)/2.0f);
                }
                else if([verticalAlignement isEqualToString:@"after"])
                {
                    CGContextTranslateCTM(quartzContext, 0, -(mySize.height-neededSize.height));
                }
            }
        
        }
        CTFrameDraw(self.frame, quartzContext);
        CGContextRestoreGState(quartzContext);
    }
}

-(CGRect) box
{
    CGRect result = CGRectZero;
    NSString* xAttribute = [self.attributes objectForKey:@"x"];
    NSString* yAttribute = [self.attributes objectForKey:@"y"];
    CGFloat x = [xAttribute floatValue];
    CGFloat y = [yAttribute floatValue];
    CGSize mySize = self.size;
    result = CGRectMake(x, y, mySize.width, mySize.height);
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = self.box;
    return result;
}

-(void)dealloc
{
    if(frame)
    {
        CFRelease(frame);
    }
    if(frameSetter)
    {
        CFRelease(frameSetter);
    }
}
@end


@implementation TextPath
-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)theContext
{
    CGContextSaveGState(quartzContext);
    CGContextConcatCTM(quartzContext, self.transform);
    
    [self addGlyphsToContext:quartzContext withSVGContext:theContext];
    
    CGContextFillPath(quartzContext);
    CGContextRestoreGState(quartzContext);
}

-(void)renderGlyphs:(NSArray*)listOfGlyphs intoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    for(GHGlyph* aGlyph in listOfGlyphs)
    {
        NSString* specialFill = aGlyph.fillDescription;
        if(specialFill.length > 0 && ![specialFill isEqualToString:@"inherited"])
        {
            // TODO fix this to be more flexible.
            UIColor* fillColor = [svgContext colorForSVGColorString:specialFill];
            CGPathRef savedPath = CGContextCopyPath(quartzContext);
            CGContextBeginPath(quartzContext);
            CGContextSaveGState(quartzContext);
            [aGlyph addPathToContext:quartzContext withSVGContext:svgContext];
            CGContextSetFillColorWithColor(quartzContext, fillColor.CGColor);
            CGContextFillPath(quartzContext);
            CGContextRestoreGState(quartzContext);
            CGContextBeginPath(quartzContext);
            if(savedPath)
            {
                CGContextAddPath(quartzContext, savedPath);
                CGPathRelease(savedPath);
            }
        }
        else
        {
            [aGlyph addPathToContext:quartzContext withSVGContext:svgContext];
        }
    }
}

-(void)addGlyphsToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    id  xlinkValue = [self.attributes objectForKey:@"xlink:href"];
    if([xlinkValue isKindOfClass:[NSString class]] && [xlinkValue hasPrefix:@"#"])
    {
        NSString* pathName = [xlinkValue substringFromIndex:1];
        GHShape* aShape = [svgContext objectNamed:pathName];
        if([aShape isKindOfClass:[GHShape class]])
        {
            CGPathRef pathRef = [aShape quartzPath];
            if(pathRef)
            {
                __block NSMutableArray* listOfGlyphs = [[NSMutableArray alloc] initWithCapacity:1024];
                [self addGlyphsToArray:listOfGlyphs  withSVGContext:svgContext];
                if(listOfGlyphs.count)
                {
                    [GHGlyph positionGlyphs:listOfGlyphs alongCGPath:pathRef];
                    [self renderGlyphs:listOfGlyphs intoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext];
                }
            }
        }
    }
}

@end


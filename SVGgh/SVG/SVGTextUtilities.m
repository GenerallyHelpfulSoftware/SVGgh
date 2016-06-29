//
//  SVGTextUtilities.m
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
//  Created by Glenn Howes on 2/2/13.
//

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreText;
#else
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#endif

#import "SVGTextUtilities.h"
#import "SVGUtilities.h"


const double kStandardSVGFontScale = 1.2;



BOOL IsFontFamilyAvailable(NSString* fontFamilyName);


@interface SVGTextUtilities ()


+(double) addFontSizeFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) addFontFamilyFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) addFontStyleFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) addFontVariantFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) addfontWeightFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) addFontWidthFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;
+(void) determinePointSizeFromCoreTextAttributes:(NSMutableDictionary*)outAttributes givenPixelSize:(double)pixelSizeToUse;
+(void) limitCharacterSetFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes;


@end

@implementation SVGTextUtilities


+(double) defaultFontSize
{
	static double sResult = 0.0;
	if(sResult == 0.0)
	{
		CTFontRef defaultFontRef = CTFontCreateUIFontForLanguage(kCTFontUIFontUser, 0.0, 0);
		if(defaultFontRef != 0)
		{
			sResult =  CTFontGetSize(defaultFontRef);
			CFRelease(defaultFontRef);
		}
	}
	return sResult;
}

+(NSDictionary*) systemFontDescription
{
    static NSDictionary* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        CTFontRef defaultFontRef = CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, 0.0, 0);
        if(defaultFontRef != 0)
        {
            CFStringRef postscriptNameCF = CTFontCopyPostScriptName(defaultFontRef);
            NSString* postscriptName = [NSString stringWithString:(__bridge NSString*)postscriptNameCF];
            CFDictionaryRef fontTraits = CTFontCopyTraits(defaultFontRef);
            
            NSMutableDictionary* mutableResult = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary*)fontTraits];
            mutableResult[(NSString*)kCTFontNameAttribute] = postscriptName;
            
            sResult = [mutableResult copy];
            CFRelease(defaultFontRef);
            CFRelease(postscriptNameCF);
            CFRelease(fontTraits);
        }

    });
    
    return sResult;
}

+(NSString*) cleanXMLText:(NSString*)sourceText
{
    NSString* result = sourceText;
    NSRange rangeOfLineEndings = [sourceText rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    NSCharacterSet* notWhiteSpaceOrNewlines = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    if(rangeOfLineEndings.location != NSNotFound)
    {
        NSMutableString* mutableResult = [result mutableCopy];
        while(rangeOfLineEndings.location != NSNotFound)
        {
            NSRange rangeOfNotWhiteSpaceOrLineEnding = [mutableResult rangeOfCharacterFromSet:notWhiteSpaceOrNewlines options:0 range:NSMakeRange(rangeOfLineEndings.location, mutableResult.length-rangeOfLineEndings.location)];
            if(rangeOfNotWhiteSpaceOrLineEnding.location != NSNotFound)
            {
                [mutableResult replaceCharactersInRange:NSMakeRange(rangeOfLineEndings.location, rangeOfNotWhiteSpaceOrLineEnding.location-rangeOfLineEndings.location) withString:@""];
            }
            else
            {
                [mutableResult
                 replaceCharactersInRange:NSMakeRange(rangeOfLineEndings.location, mutableResult.length-rangeOfLineEndings.location) withString:@""];
            }
            rangeOfLineEndings = [mutableResult rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
        }
        [mutableResult appendString:@" "];
        result = [mutableResult copy];
    }
    return result;
}

+(NSDictionary*) fontAttributesFromSVGAttributes:(NSDictionary*)SVGattributes
{
	NSDictionary* result = nil;
	NSString*	styleString = [SVGattributes objectForKey:@"style"];
	if([styleString length])
	{
		result = AttributesFromSVGCompactAttributes(styleString);
	}
    
	NSMutableDictionary* mutableFontAttributes = [NSMutableDictionary dictionary];
	NSArray* svgAttributeKeys = [SVGattributes allKeys];
	
	for(NSString* aKeyName in svgAttributeKeys)
	{
		if([aKeyName hasPrefix:@"font"]
		   || [aKeyName hasPrefix:@"text-"])
		{
			[mutableFontAttributes setObject:[SVGattributes objectForKey:aKeyName] forKey:aKeyName];
		}
 	}
	
    if([mutableFontAttributes count])
	{
		if(result != nil)
		{
			[mutableFontAttributes addEntriesFromDictionary:result];
		}
		result = [mutableFontAttributes copy];
	}
	
	return result;
}

+(CTFontDescriptorRef)	newFontDescriptorFromAttributes:(NSDictionary*) SVGattributes baseDescriptor:(CTFontDescriptorRef)baseDescriptor
{
	CTFontDescriptorRef	result = 0;
	NSDictionary* svgStyleAttributes = [SVGTextUtilities fontAttributesFromSVGAttributes:SVGattributes];
	if(baseDescriptor == 0)
	{
		NSDictionary* coreTextAttributes = [SVGTextUtilities coreTextAttributesFromSVGStyleAttributes:svgStyleAttributes];
		if([coreTextAttributes count])
		{
			CTFontDescriptorRef unMatchedResult = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)coreTextAttributes);
            NSSet* specifiedAttributes = [NSSet setWithArray:[coreTextAttributes allKeys]];
            CTFontDescriptorRef missSizedResult = CTFontDescriptorCreateMatchingFontDescriptor (unMatchedResult,
                                                                                                (__bridge CFSetRef)specifiedAttributes
                                                                                                );
            if(missSizedResult != 0)
            {
                CFRelease(unMatchedResult);
                
                result = CTFontDescriptorCreateCopyWithAttributes (missSizedResult,
                                                                   (__bridge CFDictionaryRef)coreTextAttributes
                                                                   );
                if(result != 0)
                {
                    CFRelease(missSizedResult);
                }
                else
                {
                    result = missSizedResult;
                }
            }
            else
            {
                result = unMatchedResult;
            }
		}
		else
		{
			CTFontRef defaultFontRef = CTFontCreateUIFontForLanguage(kCTFontUIFontUser, 0.0, 0);
            if(defaultFontRef == 0)
            {
                NSString* fontName = @"Helvetica";
                CFStringRef fontNameCF = (__bridge CFStringRef)(fontName);
                defaultFontRef = CTFontCreateWithName(fontNameCF,12.0, NULL );
            }
            result =  CTFontCopyFontDescriptor(defaultFontRef);
            CFRelease(defaultFontRef);
			
		}
	}
	else
	{
		NSDictionary* coreTextAttributes = [SVGTextUtilities coreTextAttributesFromSVGStyleAttributes:svgStyleAttributes baseDescriptor:baseDescriptor];
		
		if([coreTextAttributes count] == 0)
		{
			CFRetain(baseDescriptor);
			result = baseDescriptor;
		}
		else
		{
			result =  CTFontDescriptorCreateCopyWithAttributes(baseDescriptor,
															   (__bridge CFDictionaryRef)coreTextAttributes);
		}
	}
	return result;
}

+(CTFontRef) newFontRefFromFontDescriptor:(CTFontDescriptorRef)fontDescriptor
{
    CGFloat	fontSize = 0.0;
    CFTypeRef fontSizeNumber = CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontSizeAttribute);
    if(fontSizeNumber != 0)
    {
        if(CFNumberGetTypeID() == CFGetTypeID(fontSizeNumber))
        {
            fontSize = [(__bridge NSNumber*)fontSizeNumber floatValue];
        }
        CFRelease(fontSizeNumber);
    }
    CTFontRef result = CTFontCreateWithFontDescriptor(fontDescriptor, fontSize, nil);
    return result;
}

+(NSDictionary*) coreTextAttributesFromSVGStyleAttributes:(NSDictionary*)svgStyle
{
	NSMutableDictionary* mutableResult = [NSMutableDictionary dictionary];
	if([svgStyle count] != 0)
	{
		double		pixelSizeToUse = [SVGTextUtilities addFontSizeFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontFamilyFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontStyleFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontVariantFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addfontWeightFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontWidthFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities limitCharacterSetFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		
		if(pixelSizeToUse > 0.0)
		{
			[SVGTextUtilities determinePointSizeFromCoreTextAttributes:mutableResult givenPixelSize:pixelSizeToUse];
		}
	}
	
	NSDictionary* result = nil;
	if([mutableResult count])
	{
		result = [mutableResult copy];
	}
	return result;
}

+(NSCharacterSet*) characterSetWithSVGDescription:(NSString*)svgDescription
{
	NSCharacterSet* result = nil;
	NSString*	trimmedDescription = [svgDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([svgDescription hasPrefix:@"U+"])
	{
		BOOL	gotARange = NO;
		NSArray* blocks = [trimmedDescription componentsSeparatedByString:@","];
		NSMutableCharacterSet* mutableResult = [[NSMutableCharacterSet alloc] init];
		for(NSString* aBlock in blocks)
		{
			NSString* trimmedBlock = [aBlock stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([trimmedBlock hasPrefix:@"U+"])
			{
				trimmedBlock= [trimmedBlock substringFromIndex:2];
				NSArray* subRange = [trimmedBlock componentsSeparatedByString:@"-"];
				NSString* lowString = nil;
				NSString* highString = nil;
				if([subRange count] == 1)
				{
					lowString = [aBlock stringByReplacingOccurrencesOfString:@"?" withString:@"0"];
					highString = [aBlock stringByReplacingOccurrencesOfString:@"?" withString:@"F"];
				}
				else if([subRange count] == 2)
				{
					lowString = [subRange objectAtIndex:0];
					highString = [subRange objectAtIndex:1];
				}
				NSScanner* lowScanner = [NSScanner scannerWithString:lowString];
				NSScanner* highScanner = [NSScanner  scannerWithString:highString];
				long long	lowValue, highValue;
				if([lowScanner scanLongLong:&lowValue]
				   && [highScanner scanLongLong:&highValue])
				{
					gotARange = YES;
					NSRange blockRange = NSMakeRange((NSUInteger)lowValue, (NSUInteger)(highValue-lowValue+1));
					[mutableResult addCharactersInRange:blockRange];
				}
			}
		}
		if(gotARange)
		{
			result = mutableResult;
		}
	}
	return result;
}


+(void) limitCharacterSetFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSString*	svgCharacterSet = [svgStyle objectForKey:@"unicode-range"];
	if([svgCharacterSet length])
	{
		NSCharacterSet* characterSetToUse = [SVGTextUtilities characterSetWithSVGDescription:svgCharacterSet];
		
		if(characterSetToUse == nil)
		{
			[outAttributes removeObjectForKey:(NSString*)kCTFontCharacterSetAttribute];
		}
		else
		{
			[outAttributes setObject:characterSetToUse forKey:(NSString*)kCTFontCharacterSetAttribute];
		}
	}
}


+(void) addTextDecorationFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
    NSString* decoration = [svgStyle objectForKey:@"text-decoration"];
    if([decoration isKindOfClass:[NSString class]] && decoration.length)
    {
        NSArray* decorations = [decoration componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for(NSString* aDecoration in decorations)
        {
            if([aDecoration isEqualToString:@"underline"])
            {
                [outAttributes setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle]  forKey:NSUnderlineStyleAttributeName];
            }
            else if([aDecoration isEqualToString:@"overline"])
            {
                
            }
            else if([aDecoration isEqualToString:@"line-through"]) // This does not actually work, as Core Text does not support NSStrikethroughStyleAttributeName
            {
               // [outAttributes setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle | NSUnderlinePatternSolid ] forKey:NSStrikethroughStyleAttributeName];
            }
            else if([aDecoration isEqualToString:@"blink"]) // give me a break...
            {
                
            }
            else if([aDecoration isEqualToString:@"none"])
            {
                [outAttributes removeObjectForKey:NSUnderlineStyleAttributeName];
                
                [outAttributes removeObjectForKey:NSStrikethroughStyleAttributeName];
                break;
            }
        }
    }
}

+(void) addFontWidthFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSArray* listOfFontWidths = ArrayForSVGAttribute(svgStyle, @"font-stretch");
	NSNumber* widthToUse = [outAttributes objectForKey:(NSString*)kCTFontWidthTrait];
	for(id aFontWidth in listOfFontWidths)
	{
		if([aFontWidth isKindOfClass:[NSString class]])
		{
			double	normalizedWidth = 0.0;
			if([aFontWidth isEqualToString:@"all"] ||
			   [aFontWidth isEqualToString:@"normal"])
			{
				widthToUse = nil;
				break;
			}
			else if([aFontWidth isEqualToString:@"ultra-condensed"])
			{
				normalizedWidth = -1.0;
			}
			else if([aFontWidth isEqualToString:@"extra-condensed"])
			{
				normalizedWidth = -0.75;
			}
			else if([aFontWidth isEqualToString:@"condensed"])
			{
				normalizedWidth = -0.50;
			}
			else if([aFontWidth isEqualToString:@"semi-condensed"])
			{
				normalizedWidth = -0.25;
			}
			else if([aFontWidth isEqualToString:@"semi-expanded"])
			{
				normalizedWidth = 0.25;
			}
			else if([aFontWidth isEqualToString:@"expanded"])
			{
				normalizedWidth = 0.50;
			}
			else if([aFontWidth isEqualToString:@"extra-expanded"])
			{
				normalizedWidth = 0.75;
			}
			else if([aFontWidth isEqualToString:@"ultra-expanded"])
			{
				normalizedWidth = 1.0;
			}
			if(normalizedWidth != 0.0)
			{
				widthToUse = [NSNumber numberWithDouble:normalizedWidth];
				break;
			}
		}
	}
	if(widthToUse == nil)
	{
		[outAttributes removeObjectForKey:(NSString*)kCTFontWidthTrait];
	}
	else
	{
		[outAttributes setObject:widthToUse forKey:(NSString*)kCTFontWidthTrait];
	}
	
}

+(void) addfontWeightFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSArray* listOfFontWeights = ArrayForSVGAttribute(svgStyle, @"font-weight");
	BOOL foundFontTrait = NO;
	
	NSDictionary* preExistingTraits = [outAttributes objectForKey:(NSString*)kCTFontTraitsAttribute];
	if(preExistingTraits == nil)
	{
		preExistingTraits = [NSDictionary dictionary];
	}
	
	NSNumber* weightToUse = [outAttributes objectForKey:(NSString*)kCTFontWeightTrait];
	
	uint32_t	fontTraitMask = [[preExistingTraits objectForKey:(NSString*)kCTFontSymbolicTrait] unsignedIntValue];
	
	for(id aFontWeight in listOfFontWeights)
	{
		if([aFontWeight isKindOfClass:[NSString class]])
		{
			if([aFontWeight isEqualToString:@"all"]
			   || [aFontWeight isEqualToString:@"normal"]
			   || [aFontWeight isEqualToString:@"400"])
			{
				if(fontTraitMask & kCTFontBoldTrait)
				{
					foundFontTrait = YES;
					fontTraitMask &= ~kCTFontBoldTrait;
				}
				weightToUse = nil;
				break;
			}
			else if([aFontWeight isEqualToString:@"bold"]
					|| [aFontWeight isEqualToString:@"700"])
			{
				foundFontTrait = YES;
				fontTraitMask |= kCTFontBoldTrait;
				weightToUse = nil;
				break;
			}
			else if([aFontWeight intValue] >= 100
					&& [aFontWeight intValue] <= 900)
			{
				if(fontTraitMask & kCTFontBoldTrait)
				{
					foundFontTrait = YES;
					fontTraitMask &= ~kCTFontBoldTrait;
				}
				double	normalizedWeight = ([aFontWeight doubleValue]-400.0)/500.0;
				weightToUse = [NSNumber numberWithDouble:normalizedWeight];
				break;
			}
		}
	}
	if(foundFontTrait)
	{
		NSMutableDictionary* mutableTraitDictionary = [preExistingTraits mutableCopy];
		[mutableTraitDictionary setObject:[NSNumber numberWithUnsignedInt:fontTraitMask] forKey:(NSString*)kCTFontSymbolicTrait];
		[outAttributes setObject:[mutableTraitDictionary copy] forKey:(NSString*)kCTFontTraitsAttribute];
	}
	if(weightToUse == nil)
	{
		[outAttributes removeObjectForKey:(NSString*)kCTFontWeightTrait];
	}
	else
	{
		[outAttributes setObject:weightToUse forKey:(NSString*)kCTFontWeightTrait];
	}
}

+(void) addFontVariantFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSArray* listOfFontVariants= ArrayForSVGAttribute(svgStyle, @"font-variant");
	for(id aFontVariant in listOfFontVariants)
	{
		if([aFontVariant isEqualToString:@"normal"])
		{
			[outAttributes removeObjectForKey:(NSString*)kCTFontFeatureSelectorIdentifierKey];
		}
		else if([aFontVariant isEqualToString:@"small-caps"])
		{
			[outAttributes setObject:[NSNumber numberWithInt:3] forKey:(NSString*)kCTFontFeatureSelectorIdentifierKey];
		}
	}
}

+(void) determinePointSizeFromCoreTextAttributes:(NSMutableDictionary*)outAttributes givenPixelSize:(double)pixelSizeToUse
{
	CTFontDescriptorRef	tempFontDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)outAttributes);
	if(tempFontDescriptor != 0)
	{
		CTFontRef fontRef = CTFontCreateWithFontDescriptor(tempFontDescriptor, 100, nil);
		
		if(fontRef)
		{
			CGFloat hundredAscent = CTFontGetAscent(fontRef);
			CGFloat hundredDescent = CTFontGetDescent(fontRef);
			CGFloat	hundredHeight = hundredAscent+hundredDescent;
			if(hundredHeight > 0.0)
			{
				CGFloat pointSizeToUse = 100.0*pixelSizeToUse/hundredHeight;
				[outAttributes setObject:[NSNumber numberWithFloat:pointSizeToUse] forKey:(NSString*)kCTFontSizeAttribute];
			}
			
			
			CFRelease(fontRef);
		}
		
		CFRelease(tempFontDescriptor);
	}
}

+(NSAttributedString*) attributedStringFromString:(NSString*)text
                        nonFontSVGStyleAttributes:(NSDictionary*)aDefinition
                                         baseFont:(CTFontRef)myFontRef
                               baseFontDescriptor:(CTFontDescriptorRef)myFontDescription
                            includeParagraphStyle:(BOOL)includeParagraphStyle
{
	NSMutableDictionary*	mutableAttributes = [NSMutableDictionary dictionary];
	[mutableAttributes setObject:(__bridge id)myFontRef forKey:(NSString*)kCTFontAttributeName];
    BOOL useContextColor = YES;
    /* NSString* fillAttribute = [aDefinition objectForKey:@"fill"];
   if([fillAttribute length])
    {
        UIColor* fontColor = UIColorFromSVGColorString (fillAttribute);
        if(fontColor)
        {
            [mutableAttributes setObject:(id)fontColor.CGColor forKey:(NSString*)kCTForegroundColorAttributeName];
            useContextColor = NO;
        }
    }*/
    [mutableAttributes setObject:[NSNumber numberWithBool:useContextColor] forKey:(NSString*)kCTForegroundColorFromContextAttributeName];
    [SVGTextUtilities addTextDecorationFromSVGStyleAttributes:aDefinition toCoreTextAttributes:mutableAttributes];
    if(includeParagraphStyle)
    {
        CTTextAlignment lineAlignment = kCTTextAlignmentNatural;
        NSString* alignmentString = [aDefinition objectForKey:@"text-align"];
        if(alignmentString.length)
        {
            if([alignmentString isEqualToString:@"start"])
            {
                lineAlignment = kCTTextAlignmentLeft;
            }
            else if([alignmentString isEqualToString:@"end"])
            {
                lineAlignment = kCTTextAlignmentRight;
            }
            else if([alignmentString isEqualToString:@"center"])
            {
                lineAlignment = kCTTextAlignmentCenter;
            }
        }
        
        CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
        
        CGFloat lineHeight = CTFontGetAscent(myFontRef) + CTFontGetDescent(myFontRef);
        NSString* lineHeightString = [aDefinition objectForKey:@"line-increment"];
        CGFloat lineSpacing = 0;
        if([lineHeightString length] && ![lineHeightString isEqualToString:@"auto"])
        {
            CGFloat lineSpacingPossible = [lineHeightString floatValue];
            if(lineSpacingPossible > 0)
            {
                lineSpacing = lineSpacingPossible;
                lineHeight = lineSpacing;
            }
        }
        
        
        CTParagraphStyleSetting paragraphStyles[] = (CTParagraphStyleSetting[]){
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(float_t), (float_t[]){ 0.01f } },
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(float_t), (float_t[]){ lineHeight } },
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(float_t), (float_t[]){ lineHeight } },
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierLineSpacingAdjustment, sizeof(float_t), (float_t[]){ lineSpacing } },
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(float_t), (float_t[]){ lineSpacing } },
            (CTParagraphStyleSetting){ kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(float_t), (float_t[]){ lineSpacing } },
            {kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode},
            {kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &lineAlignment},
            
        };
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(
                                                                    paragraphStyles,
                                                                    2);
        [mutableAttributes setObject:(__bridge id)(paragraphStyle)  forKey:(NSString*)kCTParagraphStyleAttributeName];
        CFRelease(paragraphStyle);
        
    }
    
	NSAttributedString* result = [[NSAttributedString alloc] initWithString:text attributes:mutableAttributes];
	return result;
}

+(NSAttributedString*) attributedStringFromString:(NSString*)text
                               SVGStyleAttributes:(NSDictionary*)aDefinition
                                         baseFont:(CTFontRef)baseFont
                               baseFontDescriptor:(CTFontDescriptorRef)baseAttributes
                            includeParagraphStyle:(BOOL) includeParagraphStyle
{
	CTFontRef	fontToUse = baseFont;
	
	CTFontDescriptorRef	fontDescriptorToUse =  [SVGTextUtilities newFontDescriptorFromAttributes:aDefinition baseDescriptor:baseAttributes];
	if(fontDescriptorToUse == baseAttributes && baseFont != 0)
	{
		CFRetain(baseFont);
	}
	else
	{
		CGFloat	fontSize = 0.0;
		CFTypeRef fontSizeNumber = CTFontDescriptorCopyAttribute(fontDescriptorToUse, kCTFontSizeAttribute);
		if(fontSizeNumber != 0)
		{
			if(CFNumberGetTypeID() == CFGetTypeID(fontSizeNumber))
			{
				fontSize = [(__bridge NSNumber*)fontSizeNumber floatValue];
			}
			CFRelease(fontSizeNumber);
		}
		fontToUse = CTFontCreateWithFontDescriptor(fontDescriptorToUse, fontSize, nil);
	}
    
	NSAttributedString* result = [SVGTextUtilities attributedStringFromString:text nonFontSVGStyleAttributes:aDefinition baseFont:fontToUse baseFontDescriptor:fontDescriptorToUse includeParagraphStyle:includeParagraphStyle];
	
	if(fontToUse != 0)
	{
		CFRelease(fontToUse);
	}
	
    if(fontDescriptorToUse != 0)
    {
        CFRelease(fontDescriptorToUse);
    }
	return result;
}

+(NSDictionary*) coreTextAttributesFromSVGStyleAttributes:(NSDictionary*)svgStyle baseDescriptor:(CTFontDescriptorRef)baseDescriptor
{
	NSMutableDictionary* mutableResult = nil;
	if([svgStyle count] != 0)
	{
		CFDictionaryRef		baseAttributes = CTFontDescriptorCopyAttributes(baseDescriptor);
        if(baseAttributes != 0)
        {
            mutableResult = [(__bridge NSDictionary*)baseAttributes mutableCopy];
            CFRelease(baseAttributes);
        }
        else
        {
            mutableResult = [[NSMutableDictionary alloc] init];
        }
		double		pixelSizeToUse = [SVGTextUtilities addFontSizeFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontFamilyFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontStyleFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontVariantFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addfontWeightFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities addFontWidthFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		[SVGTextUtilities limitCharacterSetFromSVGStyleAttributes:svgStyle toCoreTextAttributes:mutableResult];
		
		if(pixelSizeToUse > 0.0)
		{
			[SVGTextUtilities determinePointSizeFromCoreTextAttributes:mutableResult givenPixelSize:pixelSizeToUse];
		}
	}
	
	NSDictionary* result = nil;
	if([mutableResult count])
	{
		result = [mutableResult copy];
	}
	return result;
}

+(void) addFontStyleFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSArray* listOfFontStyles = ArrayForSVGAttribute(svgStyle, @"font-style");
	BOOL foundFontTrait = NO;
	
	NSDictionary* preExistingTraits = [outAttributes objectForKey:(NSString*)kCTFontTraitsAttribute];
	if(preExistingTraits == nil)
	{
		preExistingTraits = [NSDictionary dictionary];
	}
	uint32_t	fontTraitMask = [[preExistingTraits objectForKey:(NSString*)kCTFontSymbolicTrait] unsignedIntValue];
	
	for(id aFontStyle in listOfFontStyles)
	{
		if([aFontStyle isKindOfClass:[NSString class]])
		{
			if([aFontStyle isEqualToString:@"all"])
			{
				foundFontTrait = YES;
			}
			else if([aFontStyle isEqualToString:@"normal"])
			{
				foundFontTrait = YES;
				fontTraitMask &= ~(kCTFontItalicTrait);
			}
			else if([aFontStyle isEqualToString:@"italic"])
			{
				foundFontTrait = YES;
				fontTraitMask |= kCTFontItalicTrait;
			}
			else if([aFontStyle isEqualToString:@"oblique"])
			{
				foundFontTrait = YES;
				fontTraitMask |= kCTFontItalicTrait;
			}
		}
	}
	
	if(foundFontTrait)
	{
		NSMutableDictionary* mutableTraitDictionary = [preExistingTraits mutableCopy];
		[mutableTraitDictionary setObject:[NSNumber numberWithUnsignedInt:fontTraitMask] forKey:(NSString*)kCTFontSymbolicTrait];
		[outAttributes setObject:[mutableTraitDictionary copy] forKey:(NSString*)kCTFontTraitsAttribute];
	}
}

+(double) addFontSizeFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	double	result = 0.0;
	NSNumber*	baseFontSize = [outAttributes objectForKey:(NSString*)kCTFontSizeAttribute];
	if([baseFontSize doubleValue] <= 0.0)
	{
		baseFontSize = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]];
	}
	NSNumber* sizeToUse = nil;
	NSArray* listOfSizeAttributes = ArrayForSVGAttribute(svgStyle, @"font-size");
	
	for(id aSizeAttribute in listOfSizeAttributes)
	{
		sizeToUse = [SVGTextUtilities fontSizeFromSVGAttribute:aSizeAttribute givenBaseSize:baseFontSize];
		if([sizeToUse doubleValue] > 0.0)
		{
			break;
		}
		else if([aSizeAttribute isKindOfClass:[NSString class]]
				&& [aSizeAttribute hasSuffix:@"px"]
				&& [aSizeAttribute doubleValue] > 0.0)
		{
			result = [aSizeAttribute doubleValue];
			break;
		}
	}
	
	if(sizeToUse != nil && [sizeToUse doubleValue] > 0.0)
	{
		[outAttributes setObject:sizeToUse forKey:(NSString*)kCTFontSizeAttribute];
	}
	return result;
}


+(NSNumber*) fontSizeFromSVGAttribute:(id)aSizeAttribute givenBaseSize:(NSNumber*) aBaseSize
{
	NSNumber* result = nil;
	if([aSizeAttribute isKindOfClass:[NSString class]])
	{
		if([aSizeAttribute isEqualToString:@"medium"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]];
		}
		else if([aSizeAttribute isEqualToString:@"small"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]/kStandardSVGFontScale];
		}
		else if([aSizeAttribute isEqualToString:@"large"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]*kStandardSVGFontScale];
		}
		else if([aSizeAttribute isEqualToString:@"x-small"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]/(kStandardSVGFontScale*kStandardSVGFontScale)];
		}
		else if([aSizeAttribute isEqualToString:@"x-large"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]*(kStandardSVGFontScale*kStandardSVGFontScale)];
		}
		else if([aSizeAttribute isEqualToString:@"xx-large"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]*(kStandardSVGFontScale*kStandardSVGFontScale*kStandardSVGFontScale)];
		}
		else if([aSizeAttribute isEqualToString:@"xx-small"])
		{
			result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]/(kStandardSVGFontScale*kStandardSVGFontScale*kStandardSVGFontScale)];
		}
		else if([aSizeAttribute isEqualToString:@"larger"] && [aBaseSize doubleValue] > 0.0)
		{
			result = [NSNumber numberWithDouble:[aBaseSize doubleValue]*kStandardSVGFontScale];
		}
		else if([aSizeAttribute isEqualToString:@"smaller"] && [aBaseSize doubleValue] > 0.0)
		{
			result = [NSNumber numberWithDouble:[aBaseSize doubleValue]/kStandardSVGFontScale];
		}
		else if([aSizeAttribute isEqualToString:@"inherit"])
		{
			if([aBaseSize doubleValue] > 0.0)
			{
				result = aBaseSize;
			}
			else
			{
				result = [NSNumber numberWithDouble:[SVGTextUtilities defaultFontSize]];
			}
		}
		else if([aSizeAttribute hasSuffix:@"%"])
		{
			if([aBaseSize doubleValue] > 0.0)
			{
				double percentage = [aSizeAttribute doubleValue]/100.0;
				if(percentage > 0.0)
				{
					result = [NSNumber numberWithDouble:[aBaseSize doubleValue]*percentage];
				}
			}
		}
		else if([aSizeAttribute hasSuffix:@"em"])
		{
			if([aBaseSize doubleValue] > 0.0)
			{
				double numberOfEms = [aSizeAttribute doubleValue];
				if(numberOfEms > 0.0)
				{
					result = [NSNumber numberWithDouble:[aBaseSize doubleValue]*numberOfEms];
				}
			}
			
		}
		else if([aSizeAttribute hasSuffix:@"pt"])
		{
			double absolutePoints = [aSizeAttribute doubleValue];
			if(absolutePoints > 0.0)
			{
				result = [NSNumber numberWithDouble:absolutePoints];
			}
		}
		else if([aSizeAttribute hasSuffix:@"px"])
		{
			
		}
		else if([aSizeAttribute doubleValue] > 0)
		{
			double absolutePoints = [aSizeAttribute doubleValue];
			if(absolutePoints > 0.0)
			{
				result = [NSNumber numberWithDouble:absolutePoints];
			}
		}
	}
	else if([aSizeAttribute isKindOfClass:[NSNumber class]]
			&& [aSizeAttribute doubleValue] > 0.0)
	{
		result = (NSNumber*)aSizeAttribute;
	}
	
	
	return result;
}


+(NSDictionary*) fontFamilyAttributesFromSVGAttribute:(id)aFontFamilyAttribute higherPriorityAttributes:(NSDictionary*)startingAttributes
{
	NSMutableDictionary* mutableResult = [NSMutableDictionary dictionary];
	if([startingAttributes count])
	{
		[mutableResult addEntriesFromDictionary:startingAttributes];
	}
	NSDictionary* preExistingTraits = [mutableResult objectForKey:(NSString*)kCTFontTraitsAttribute];
	if(preExistingTraits == nil)
	{
		preExistingTraits = [NSDictionary dictionary];
	}
	if([aFontFamilyAttribute isKindOfClass:[NSString class]])
	{
		uint32_t	fontTraitMask = [[preExistingTraits objectForKey:(NSString*)kCTFontSymbolicTrait] unsignedIntValue];
		if([aFontFamilyAttribute isEqualToString:@"serif"])
		{
			fontTraitMask &= ~kCTFontClassMaskTrait;
            fontTraitMask |= kCTFontOldStyleSerifsClass;
		}
		else if([aFontFamilyAttribute isEqualToString:@"sans-serif"])
		{
			fontTraitMask &= ~kCTFontClassMaskTrait;
			fontTraitMask |= kCTFontSansSerifClass;
		}
		else if([aFontFamilyAttribute isEqualToString:@"cursive"])
		{
			fontTraitMask &= ~kCTFontClassMaskTrait;
			fontTraitMask |= kCTFontScriptsClass;
		}
		else if([aFontFamilyAttribute isEqualToString:@"fantasy"])
		{
			fontTraitMask &= ~kCTFontClassMaskTrait;
			fontTraitMask |= kCTFontOrnamentalsClass;
		}
		else if([aFontFamilyAttribute isEqualToString:@"monospace"])
		{
			fontTraitMask |= kCTFontMonoSpaceTrait;
		}
		else
		{
			NSString* unquotedString = UnquotedSVGString(aFontFamilyAttribute);
			if([unquotedString length] && [mutableResult objectForKey:(NSString*)kCTFontFamilyNameAttribute] == nil
               && [mutableResult objectForKey:(NSString*)kCTFontNameAttribute] == nil)
			{ // if I didn't set this before with a fontname that exists on this system.
                
                if([unquotedString isEqualToString:@"system"]) // this is as of yet not a W3C standard, could use -apple-system
                {
                    NSDictionary* systemFontAttributes = [self systemFontDescription];
                    [mutableResult addEntriesFromDictionary:systemFontAttributes];
                }
				else if(IsFontFamilyAvailable(unquotedString))
				{
					[mutableResult setObject:unquotedString forKey:(NSString*)kCTFontFamilyNameAttribute];
				}
			}
		}
		if(fontTraitMask != 0)
		{
			NSMutableDictionary* mutableTraitDictionary = [preExistingTraits mutableCopy];
			[mutableTraitDictionary setObject:[NSNumber numberWithUnsignedInt:fontTraitMask] forKey:(NSString*)kCTFontSymbolicTrait];
			[mutableResult setObject:[mutableTraitDictionary copy] forKey:(NSString*)kCTFontTraitsAttribute];
		}
	}
	
	NSDictionary* result = nil;
	if([mutableResult count])
	{
		result = [mutableResult copy];
	}
	return result;
}

+(void) addFontFamilyFromSVGStyleAttributes:(NSDictionary*)svgStyle toCoreTextAttributes:(NSMutableDictionary*)outAttributes
{
	NSDictionary* fontFamilyDescription = nil;
	
	NSArray* listOfFontFamilies =  ArrayForSVGAttribute(svgStyle, @"font-family");
	
	for(id aFontFamilyName in listOfFontFamilies)
	{
		fontFamilyDescription = [SVGTextUtilities fontFamilyAttributesFromSVGAttribute:aFontFamilyName higherPriorityAttributes:fontFamilyDescription];
        if([fontFamilyDescription objectForKey:(NSString*)kCTFontFamilyNameAttribute] != nil)
        {
            break;
        }
	}
	
	if([fontFamilyDescription count])
	{
		[outAttributes addEntriesFromDictionary:fontFamilyDescription];
	}
    else
    {
        NSDictionary* defaultFontDescription = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCTFontSansSerifClass] forKey:(NSString*)kCTFontSymbolicTrait];
        [outAttributes setObject:defaultFontDescription forKey:(NSString*)kCTFontTraitsAttribute];
    }
    
}


@end



BOOL IsFontFamilyAvailable(NSString* fontFamilyName)
{
	BOOL result = NO;
    if(fontFamilyName.length)
    { // turns out that the call CTFontCreateWithName is fairly slow, so I'm caching the availability results.
        static NSCache* sCache = nil;
        static dispatch_once_t  done;
        dispatch_once(&done, ^{
            sCache = [[NSCache alloc] init];
            sCache.name = @"Font Available Cache";
        });
        
        NSNumber* boolResult = [sCache objectForKey:fontFamilyName];
        if(boolResult == nil)
        {
            NSString* stringToTest = fontFamilyName;
            CTFontRef	testFont = CTFontCreateWithName((__bridge CFStringRef)stringToTest, 0.0, NULL);
            if(testFont != 0)
            {
                CFStringRef testName = CTFontCopyFamilyName(testFont);
                if(testName != 0)
                {
                    result = [stringToTest isEqualToString:(__bridge NSString*)testName];
                    CFRelease(testName);
                }
                CFRelease(testFont);
            }
            
            [sCache setObject:[NSNumber numberWithBool:result] forKey:fontFamilyName];
        }
        else
        {
            result = boolResult.boolValue;
        }
    }
	return result;
}

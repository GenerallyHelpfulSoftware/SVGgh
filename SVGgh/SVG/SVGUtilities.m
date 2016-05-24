//
//  SVGUtilities.m
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

//  Created by Glenn Howes on 1/11/13.
//

#import "SVGUtilities.h"
#import "NSData+Base64Additions.h"
#import "SVGAttributedObject.h"
#import "GHImageCache.h"
#import "SVGUtilities.h"

const CGFloat kDegreesToRadiansConstant = (CGFloat)(M_PI/180.0);

NSString* const	kWhiteInHex = @"#FFFFFF";
NSString* const   kBlackInHex = @"#000";


CGFloat CalculateVectorRatio(CGPoint	vector1, CGPoint vector2);
CGFloat CalculateVectorMagnitude(CGPoint aVector);

// misusing CGPoint as a vector for laziness
CGFloat CalculateVectorMagnitude(CGPoint aVector)
{
	CGFloat	result = sqrtf(aVector.x*aVector.x+aVector.y*aVector.y);
	
	
	return result;
}

BOOL IsStringURL(NSString* aString)
{
    BOOL result = ([aString hasPrefix:@"url("] || [aString hasPrefix:@"URL("]) &&  [aString hasSuffix:@")"];
    return result;
}


NSString* ExtractURLContents(NSString* aString)
{
    NSString* result = @"";
    if(IsStringURL(aString))
    {
        result = [aString substringWithRange:NSMakeRange(4, [aString length]-5)];
    }
    return result;
}

CGFloat CalculateVectorRatio(CGPoint	vector1, CGPoint vector2)
{
	CGFloat	result = vector1.x*vector2.x+vector1.y*vector2.y;
	result /= (CalculateVectorMagnitude(vector1)*CalculateVectorMagnitude(vector2));
	return result;
}

CGFloat CalculateVectorAngle(CGPoint	vector1, CGPoint vector2)
{
	CGFloat	vectorRatio = CalculateVectorRatio(vector1, vector2);
	
	CGFloat	result = acosf(vectorRatio);
	
	if((vector1.x*vector2.y) < (vector1.y*vector2.x))
	{
		result *= -1.0;
	}
	return result;
}

NSDictionary* DefaultSVGDrawingAttributes()
{
    static NSDictionary* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"1", @"stroke-width",
                   @"1.0", @"opacity",
                   @"4", @"stroke-miterlimit",
                   @"miter", @"stroke-linejoin",
                   @"butt", @"stroke-linecap",
                   @"none",@"stroke-dasharray",
                   nil];
    });
    return sResult;
}

NSSet* StandardPathAttributes()
{
    static NSSet* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [[NSSet alloc] initWithObjects:@"style",
                     @"stroke-width",
                     @"vector-effect",
                     @"stroke-miterlimit",
                     @"stroke-linejoin",
                     @"stroke-linecap",
                     @"stroke-dasharray",
                     @"stroke-dashoffset",
                     @"opacity",
                     @"color",
                     @"stroke",
                     @"fill",
                     @"fill-rule",
                     @"clip-rule",
                     @"fill-opacity",
                     @"stroke-opacity",
                     nil];
    });
    
    return sResult;
}

NSString* StyleStringFromDictionary(NSDictionary* styleAttributesOnly)
{
    NSMutableString* mutableResult = [[NSMutableString alloc] init];
    NSArray* allKeys = [styleAttributesOnly allKeys];
    for(NSString* aKey in allKeys)
    {
        if(mutableResult.length)
        {
            [mutableResult appendString:@";"];
        }
        [mutableResult appendString:aKey];
        [mutableResult appendString:@":"];
        [mutableResult appendString:[styleAttributesOnly objectForKey:aKey]];
    }
    
    
    return [mutableResult copy];
}

NSDictionary* SVGMorphStyleAttributes(NSDictionary*oldAttributes, NSDictionary* newAttributes, CGFloat fractionThere)
{
    NSDictionary* result = newAttributes;
    
    if(fractionThere <= 0.0)
    {
        result = oldAttributes;
    }
    else if(fractionThere < 1.0)
    {
        NSDictionary* oldStyles = [SVGToQuartz dictionaryForStyleAttributeString:[oldAttributes objectForKey:@"style"]];
        NSDictionary* newStyles = [SVGToQuartz dictionaryForStyleAttributeString:[newAttributes objectForKey:@"style"]];
        NSMutableDictionary* morphedStyles = [newStyles mutableCopy];
        NSMutableDictionary* mutableResult = [newAttributes mutableCopy];
        
        NSString* oldStrokeWidth = oldAttributes[@"stroke-width"];
        if(oldStrokeWidth == nil) oldStrokeWidth = oldStyles[@"stroke-width"];
        
        NSString* newStrokeWidth = newAttributes[@"stroke-width"];
        if(newStrokeWidth == nil) newStrokeWidth = newStyles[@"stroke-width"];
        
        if(oldStrokeWidth != nil && newStrokeWidth != nil && ![oldStrokeWidth isEqualToString:newStrokeWidth])
        {
            [mutableResult removeObjectForKey:@"stroke-width"];
            CGFloat newStrokeValue = [newStrokeWidth floatValue];
            CGFloat oldStrokeValue = [oldStrokeWidth floatValue];
            CGFloat morphedStrokeValue = oldStrokeValue+(newStrokeValue-oldStrokeValue)*fractionThere;
            [morphedStyles setValue:[[NSNumber numberWithFloat:morphedStrokeValue] stringValue] forKey:@"stroke-width"];
        }
        NSString* oldOpacity = oldAttributes[@"opacity"];
        if(oldOpacity == nil) oldOpacity = oldStyles[@"opacity"];
        
        NSString* newOpacity = newAttributes[@"opacity"];
        if(newOpacity == nil) newOpacity = newStyles[@"opacity"];
        
        if(oldOpacity != nil && newOpacity != nil && ![oldOpacity isEqualToString:newOpacity])
        {
            [mutableResult removeObjectForKey:@"opacity"];
            CGFloat newValue = [newOpacity floatValue];
            CGFloat oldValue = [oldOpacity floatValue];
            CGFloat morphedValue = oldValue+(newValue-oldValue)*fractionThere;
            [morphedStyles setValue:[[NSNumber numberWithFloat:morphedValue] stringValue] forKey:@"opacity"];
        }
        
        
        NSString* oldFillOpacity = oldAttributes[@"fill-opacity"];
        if(oldFillOpacity == nil) oldFillOpacity = oldStyles[@"fill-opacity"];
        
        NSString* newFillOpacity = newAttributes[@"fill-opacity"];
        if(newFillOpacity == nil) newFillOpacity = newStyles[@"fill-opacity"];
        
        if(oldFillOpacity != nil && newFillOpacity != nil && ![oldFillOpacity isEqualToString:newFillOpacity])
        {
            [mutableResult removeObjectForKey:@"fill-opacity"];
            CGFloat newValue = [newFillOpacity floatValue];
            CGFloat oldValue = [oldFillOpacity floatValue];
            CGFloat morphedValue = oldValue+(newValue-oldValue)*fractionThere;
            [morphedStyles setValue:[[NSNumber numberWithFloat:morphedValue] stringValue] forKey:@"fill-opacity"];
        }
        
        NSString* oldColor = oldAttributes[@"color"];
        if(oldColor == nil) oldColor = oldStyles[@"color"];
        
        NSString* newColor = newAttributes[@"color"];
        if(newColor == nil) newColor = newStyles[@"color"];
        
        if(oldColor != nil && newColor != nil && ![oldColor isEqualToString:newColor])
        {
            [mutableResult removeObjectForKey:@"color"];
            NSString* morphedColor = MorphColorString(oldColor, newColor, fractionThere);
            [morphedStyles setValue:morphedColor forKey:@"color"];
        }
        
        
        oldColor = oldAttributes[@"fill"];
        if(oldColor == nil) oldColor = oldStyles[@"fill"];
        
        newColor = newAttributes[@"fill"];
        if(newColor == nil) newColor = newStyles[@"fill"];
        
        if(oldColor != nil && newColor != nil && ![oldColor isEqualToString:newColor])
        {
            [mutableResult removeObjectForKey:@"fill"];
            NSString* morphedColor = MorphColorString(oldColor, newColor, fractionThere);
            [morphedStyles setValue:morphedColor forKey:@"fill"];
        }
        
        
        oldColor = oldAttributes[@"stroke"];
        if(oldColor == nil) oldColor = oldStyles[@"stroke"];
        
        newColor = newAttributes[@"stroke"];
        if(newColor == nil) newColor = newStyles[@"stroke"];
        
        if(oldColor != nil && newColor != nil && ![oldColor isEqualToString:newColor])
        {
            [mutableResult removeObjectForKey:@"stroke"];
            NSString* morphedColor = MorphColorString(oldColor, newColor, fractionThere);
            [morphedStyles setValue:morphedColor forKey:@"stroke"];
        }
        
        [mutableResult setObject:StyleStringFromDictionary(morphedStyles) forKey:@"style"];
        result = [mutableResult copy];
    }
    return result;
}

NSDictionary* SVGMergeStyleAttributes(NSDictionary* parentAttributes, NSDictionary* attributesToMergeIn, attribute_replacement_filter_t filter)
{
    NSDictionary* parentStyleAttributes = [SVGToQuartz dictionaryForStyleAttributeString:[parentAttributes objectForKey:@"style"]];
    NSDictionary* mergeInStyleAttributes = [SVGToQuartz dictionaryForStyleAttributeString:[attributesToMergeIn objectForKey:@"style"]];
                                           
    NSMutableDictionary* mutableResult = (parentAttributes==nil)?[[NSMutableDictionary alloc]initWithCapacity:32]:[parentAttributes mutableCopy];
   [mutableResult removeObjectForKey:@"style"];
   NSArray* startingAttributes = [parentStyleAttributes allKeys];

    NSMutableDictionary* startValues = nil;
    if(filter != nil && parentAttributes != nil)
    {
        startValues = [parentAttributes mutableCopy];
        for(id aKey in startingAttributes)
        {
            [startValues setObject:[parentStyleAttributes objectForKey:aKey] forKey:aKey];
        }
    }
    
    
    
    
   for(id aKey in startingAttributes)
   {
       id aValue = [parentStyleAttributes objectForKey:aKey];
       [mutableResult setObject:aValue forKey:aKey];
   }
    NSArray* styleAttributes = [mergeInStyleAttributes allKeys];
    
    NSSet* standardPathAttributes = StandardPathAttributes();
    for(id aKey in styleAttributes)
    {
        if([standardPathAttributes containsObject:aKey])
        {
            id aValue = [mergeInStyleAttributes objectForKey:aKey];
            if(!filter || filter(aKey, [startValues objectForKey:aKey], aValue))
            {
                [mutableResult setObject:aValue forKey:aKey];
            }
        }
    }
    
    for(id aKey in standardPathAttributes)
    {
        if(![aKey isEqualToString:@"style"])
        {
            id aValue = [attributesToMergeIn objectForKey:aKey];
            if(aValue != nil)
            {
                if(!filter || filter(aKey, [startValues objectForKey:aKey], aValue))
                {
                    [mutableResult setObject:aValue forKey:aKey];
                }
            }
        }
    }
    
    
    return [mutableResult copy];
}

NSArray* ArrayForSVGAttribute(NSDictionary* svgAttributes, NSString* key)
{
	NSArray*	result = nil;
	id anAttribute = [svgAttributes objectForKey:key];
	if([anAttribute isKindOfClass:[NSArray class]])
	{
		result = (NSArray*)anAttribute;
	}
    else if([anAttribute isKindOfClass:[NSString class]])
    {
		result = [[NSArray alloc] initWithObjects:anAttribute, nil];
        NSArray* subComponents = [anAttribute componentsSeparatedByString:@","];
        if([subComponents count])
        {
            NSMutableArray* mutableResult = [[NSMutableArray alloc] initWithCapacity:[subComponents count]];
            for(NSString* aComponent in subComponents)
            {
                NSString* trimmedComponent = [aComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                trimmedComponent = [trimmedComponent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]];
                if([trimmedComponent length])
                {
                    [mutableResult addObject:trimmedComponent];
                }
            }
            result = [mutableResult copy];
        }
    }
	else if(anAttribute != nil)
	{
		result = [[NSArray alloc] initWithObjects:anAttribute, nil];
	}
	return result;
}



NSDictionary* AttributesFromSVGCompactAttributes(NSString* compactedAttributes)
{
    NSMutableDictionary* mutableResult = [NSMutableDictionary dictionary];
	NSArray* components = [compactedAttributes componentsSeparatedByString:@";"];
	if([components count])
	{
		for(NSString* aValuePairString in components)
		{
			NSRange	rangeOfColon = [aValuePairString rangeOfString:@":"];
			if(rangeOfColon.location != NSNotFound && rangeOfColon.location > 0
			   && rangeOfColon.location < [aValuePairString length])
			{
				NSString*	keyString = [[aValuePairString substringToIndex:rangeOfColon.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				NSString*	valueString = [[aValuePairString substringFromIndex:rangeOfColon.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				NSArray* subComponents = [valueString componentsSeparatedByString:@","];
				if([subComponents count] > 1)
				{
					[mutableResult setObject:subComponents forKey:keyString];
				}
				else if([valueString length])
				{
					[mutableResult setObject:valueString forKey:keyString];
				}
			}
		}
	}
	return [mutableResult copy];
}

NSString* UnquotedSVGString(NSString* possiblyQuotedString)
{
	NSString*	result = [possiblyQuotedString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"]];
	return result;
}


// From AtomicElementView.m (Apple example code)
CGContextRef BitmapContextCreate (size_t pixelsWide,
                                         size_t pixelsHigh)
{
    CGContextRef bitmapContext = 0;
    CGColorSpaceRef colorSpace;
	
    colorSpace = CGColorSpaceCreateDeviceRGB();
	
	
	// create the bitmap context
    bitmapContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8,
										   pixelsWide*4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	
	// free the rgb colorspace
    CGColorSpaceRelease(colorSpace);
	
	// return the bitmap context
    return bitmapContext;
}

NSString* CGAffineTransformToSVGTransform(CGAffineTransform aTransform)
{
    NSString* result = [[NSString alloc] initWithFormat:@"matrix(%g %g %g %g %g %g)",
                        aTransform.a, aTransform.b, aTransform.c, aTransform.d, aTransform.tx, aTransform.ty];
    
    return result;
}


NSString* SVGTransformMorph(NSString* oldtransform, NSString* newTransform, CGFloat fraction)
{
    CGAffineTransform oldAffine = SVGTransformToCGAffineTransform(oldtransform);
    CGAffineTransform newAffine = SVGTransformToCGAffineTransform(newTransform);
    CGAffineTransform morphedTranform;
    morphedTranform.a = oldAffine.a+(newAffine.a-oldAffine.a)*fraction;
    morphedTranform.b = oldAffine.b+(newAffine.b-oldAffine.b)*fraction;
    morphedTranform.c = oldAffine.c+(newAffine.c-oldAffine.c)*fraction;
    morphedTranform.d = oldAffine.d+(newAffine.d-oldAffine.d)*fraction;
    morphedTranform.tx = oldAffine.tx+(newAffine.tx-oldAffine.tx)*fraction;
    morphedTranform.ty = oldAffine.ty+(newAffine.ty-oldAffine.ty)*fraction;
    NSString* result = CGAffineTransformToSVGTransform(morphedTranform);
    return result;
    
}

typedef enum  TransformOperationsEnum{
    kUnknownTransformOperation = 0,
    kMatrixOperation = 1,
    kTranslateOperation = 2,
    kRotateOperation,
    kScaleOperation,
    kSkewXOperation,
    kSkewYOperation,
    
}TransformOperationsEnum;

CGAffineTransform SVGTransformToCGAffineTransformSlow(NSString* transformAttribute);

CGAffineTransform SVGTransformToCGAffineTransform(NSString* transformAttribute)
{
	CGAffineTransform	result = CGAffineTransformIdentity;
    NSUInteger stringLength = transformAttribute.length;
    if(stringLength > 8 && stringLength < 255)
    {
        NSUInteger stringIndex = 0;
        char stringBuffer[256]; // YES. I should learn Regular Expressions.
        char numberBuffer[256];
        if([transformAttribute  getCString:stringBuffer maxLength:255 encoding:NSASCIIStringEncoding])
        {
            while(stringIndex < stringLength)
            {
                BOOL	failed = NO;
                NSUInteger stringLeft = stringLength-stringIndex;
                char aChar = stringBuffer[stringIndex];
                NSUInteger maxParameters = 0;
                
                TransformOperationsEnum activeOperation = kUnknownTransformOperation;
                switch (aChar) {
                    case 'm':
                    {
                        if(stringLeft >= 18 && (strncmp(&stringBuffer[stringIndex], "matrix", 6) == 0))
                        {
                            stringIndex+= 6;
                            activeOperation = kMatrixOperation;
                            maxParameters= 6;
                        }
                        else
                        {
                            failed = YES;
                        }
                    }
                    break;
                    case 't':
                    {
                        if(stringLeft >= 12 && (strncmp(&stringBuffer[stringIndex], "translate", 9) == 0))
                        {
                            maxParameters= 2;
                            stringIndex+= 9;
                            activeOperation = kTranslateOperation;
                        }
                        else
                        {
                            failed = YES;
                        }
                    }
                    break;
                    case 'r':
                    {
                        if(stringLeft >= 9 && (strncmp(&stringBuffer[stringIndex], "rotate", 6) == 0))
                        {
                            stringIndex+= 6;
                            activeOperation = kRotateOperation;
                            maxParameters= 3;
                        }
                        else
                        {
                            failed = YES;
                        }
                    }
                    break;
                    case 's':
                    {
                        if(stringLeft >= 8 && (strncmp(&stringBuffer[stringIndex], "scale", 5) == 0))
                        {
                            activeOperation = kScaleOperation;
                            maxParameters= 2;
                            stringIndex+= 5;
                        }
                        else if(stringLeft >= 8 && (strncmp(&stringBuffer[stringIndex], "skewY", 5) == 0))
                        {
                            activeOperation = kSkewYOperation;
                            maxParameters= 1;
                            stringIndex+= 5;
                        }
                        else if(stringLeft >= 8 && (strncmp(&stringBuffer[stringIndex], "skewX", 5) == 0))
                        {
                            activeOperation = kSkewXOperation;
                            maxParameters= 1;
                            stringIndex+= 5;
                        }
                        else
                        {
                            failed = YES;
                        }
                    }
                    break;
                        
                    default:
                        stringIndex+=1;
                    break;
                }
                
                
                
                if(activeOperation != kUnknownTransformOperation)
                {
                    float parameters[6];
                    NSUInteger parameterIndex = 0;
                    BOOL foundParenthesis = NO;
                    while(stringIndex < stringLength)
                    {
                        aChar = stringBuffer[stringIndex++];
                        if(aChar == '(')
                        {
                            foundParenthesis = YES;
                            break;
                        }
                    }
                    
                    if(foundParenthesis)
                    {
                        BOOL foundEndParenthesis = NO;
                        while(stringIndex < stringLength && !foundEndParenthesis && !failed)
                        {
                            aChar = stringBuffer[stringIndex];
                            
                            NSUInteger beginNumberIndex = 0;
                            BOOL numberSeen = NO;
                            BOOL periodSeen = NO;
                            while(beginNumberIndex == 0 && foundEndParenthesis == NO && stringIndex < stringLength)
                            {
                                if(aChar == '-')
                                {
                                    beginNumberIndex = stringIndex++;
                                }
                                else if(aChar == '.')
                                {
                                    beginNumberIndex = stringIndex++;
                                    periodSeen = YES;
                                }
                                else if(aChar >= '0' && aChar <= '9')
                                {
                                    beginNumberIndex = stringIndex++;
                                    numberSeen = YES;
                                }
                                else if(aChar == ')')
                                {
                                    foundEndParenthesis = YES;
                                    stringIndex++;
                                }
                                else
                                {
                                    stringIndex++;
                                }
                                aChar = stringBuffer[stringIndex];
                            }
                            
                            if(beginNumberIndex > 0)
                            {
                                NSUInteger endNumIndex = beginNumberIndex;
                                while(stringIndex < stringLength)
                                {
                                    aChar = stringBuffer[stringIndex++];
                                    if(aChar >= '0' && aChar <= '9')
                                    {
                                        numberSeen = YES;
                                        endNumIndex++;
                                    }
                                    else if(aChar == '.' && !periodSeen)
                                    {
                                        periodSeen = YES;
                                        endNumIndex++;
                                    }
                                    else if(aChar == ')')
                                    {
                                        foundEndParenthesis = YES;
                                        break;
                                    }
                                    else
                                    {
                                        break;
                                    }
                                }
                                if(numberSeen)
                                {
                                    memcpy(numberBuffer, &stringBuffer[beginNumberIndex], endNumIndex-beginNumberIndex+1);
                                    numberBuffer[endNumIndex-beginNumberIndex+1]= 0;
                                    if(periodSeen)
                                    {
                                        parameters[parameterIndex++]  = atof(numberBuffer);
                                    }
                                    else
                                    {
                                        parameters[parameterIndex++]  = atoi(numberBuffer);
                                    }
                                }
                                else
                                {
                                    failed = YES;
                                }
                            }
                            if(parameterIndex > maxParameters)
                            {
                                failed = YES;
                            }
                        }
                    }
                    else
                    {
                        failed = YES;
                    }
                    if(!failed)
                    {
                        switch (activeOperation) {
                            case     kMatrixOperation:
                            {
                                if(parameterIndex != 6)
                                {
                                    failed = YES;
                                }
                                else
                                {
                                    CGAffineTransform specificTransform = CGAffineTransformMake(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4], parameters[5]);
                                    result = CGAffineTransformConcat(specificTransform, result);
                                }
                            }
                            break;
                            case     kTranslateOperation:
                            {
                                CGFloat	xTrans = 0.0, yTrans = 0.0;
                                switch(parameterIndex)
                                {
                                    default:
                                    case 0:
                                    {
                                        failed = YES;
                                    }
                                    break;
                                    case 2:
                                    {
                                        yTrans = parameters[1];
                                    }// deliberate fallthrough
                                    case 1:
                                    {
                                        xTrans = parameters[0];
                                        result = CGAffineTransformTranslate(result, xTrans, yTrans);
                                    }
                                    break;
                                }
                            }
                            break;
                            case    kRotateOperation:
                            {
                                CGFloat	rotationAngle = 0.0;
                                switch(parameterIndex)
                                {
                                    default:
                                    case 0:
                                    {
                                        failed = YES;
                                    }
                                    break;
                                    case 3:
                                    {
                                        CGFloat centerX = parameters[1];
                                        CGFloat centerY = parameters[2];
                                        
                                        rotationAngle = parameters[0]*kDegreesToRadiansConstant;
                                        
                                        result = CGAffineTransformTranslate(result,centerX, centerY);
                                        result = CGAffineTransformRotate(result, rotationAngle);
                                        result = CGAffineTransformTranslate(result,-1.0f*centerX, -1.0f*centerY);
                                    }
                                        break;
                                    case 1:
                                    {
                                        rotationAngle = parameters[0]*kDegreesToRadiansConstant;
                                        result = CGAffineTransformRotate(result, rotationAngle);
                                    }
                                    break;
                                }
                            }
                            break;
                            case    kScaleOperation:
                            {
                                CGFloat	xScale = 1.0, yScale = 1.0;
                                switch(parameterIndex)
                                {
                                    default:
                                    case 0:
                                    {
                                        failed = YES;
                                    }
                                    break;
                                    case 2:
                                    {
                                        yScale = parameters[1];
                                        xScale = parameters[0];
                                    }
                                    break;
                                    case 1:
                                    {
                                        yScale = xScale = parameters[0];
                                    }
                                    break;
                                }
                                result = CGAffineTransformScale(result, xScale, yScale);
                            }
                            break;
                            case    kSkewXOperation:
                            {
                                switch(parameterIndex)
                                {
                                    default:
                                    case 0:
                                    {
                                        failed = YES;
                                    }
                                    break;
                                    case 1:
                                    {
                                        CGFloat skewAngleDegrees = parameters[0];
                                        double skewAngle = skewAngleDegrees*M_PI/180.0;
                                        double	tanSkewAngle = tan(skewAngle);
                                        CGAffineTransform skewedTransform = CGAffineTransformIdentity;
                                        skewedTransform.c = (CGFloat)tanSkewAngle;
                                        
                                        result = CGAffineTransformConcat(skewedTransform, result);
                                    }
                                    break;
                                }
                            }
                            break;
                            case    kSkewYOperation:
                            {
                                switch(parameterIndex)
                                {
                                    default:
                                    case 0:
                                    {
                                        failed = YES;
                                    }
                                    break;
                                    case 1:
                                    {
                                        CGFloat skewAngleDegrees = parameters[0];
                                        double skewAngle = skewAngleDegrees*M_PI/180.0;
                                        double	tanSkewAngle = tan(skewAngle);
                                        
                                        CGAffineTransform skewedTransform = CGAffineTransformIdentity;
                                        skewedTransform.b = tanSkewAngle;
                                        result = CGAffineTransformConcat(skewedTransform, result);
                                    }
                                    break;
                                }
                            }
                            break;
                                
                            default:
                            break;
                        }
                    }
                    
                }
                if(failed)
                {
                    break;
                }
            }
        }
    }
    
    return result;
}


CGAffineTransform SVGTransformToCGAffineTransformSlow(NSString* transformAttribute)
{
	CGAffineTransform	result = CGAffineTransformIdentity;
	if([transformAttribute length])
	{
        static NSMutableCharacterSet* punctuationAndWhiteSpaceSet = nil;
        static NSMutableCharacterSet* commaAndWhiteSpaceSet = nil;
        static dispatch_once_t  done;
        dispatch_once(&done, ^{
            punctuationAndWhiteSpaceSet = [[NSMutableCharacterSet alloc] init];
            [punctuationAndWhiteSpaceSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [punctuationAndWhiteSpaceSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
            
            commaAndWhiteSpaceSet = [[NSMutableCharacterSet alloc] init];
            [commaAndWhiteSpaceSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [commaAndWhiteSpaceSet addCharactersInString:@","];

        });

		NSArray*	operations = [transformAttribute componentsSeparatedByString:@")"];
		for(__strong NSString*	anOperation in operations)
		{
			BOOL	failed = NO;
			anOperation = [anOperation stringByTrimmingCharactersInSet:punctuationAndWhiteSpaceSet];
			NSRange	rangeOfParenthesis = [anOperation rangeOfString:@"("];
			if(rangeOfParenthesis.location == NSNotFound) break;
			
			NSString*	parameterString = [anOperation substringFromIndex:rangeOfParenthesis.location+1];
			NSArray*	parameters = [parameterString componentsSeparatedByCharactersInSet:commaAndWhiteSpaceSet];
			NSMutableArray*	trimmedParameters = [parameters mutableCopy];
			
			for(NSUInteger index = [trimmedParameters count]-1; ; index--)
			{
				if([[trimmedParameters objectAtIndex:index] length] == 0) // remove any empty strings
				{
					[trimmedParameters removeObjectAtIndex:index];
				}
                if(index == 0)
                {
                    break;
                }
			}
			
			if([anOperation hasPrefix:@"matrix"])
			{
				if([trimmedParameters count] == 6)
				{
					CGAffineTransform specificTransform = CGAffineTransformMake(
                            [[trimmedParameters objectAtIndex:0] floatValue],
                            [[trimmedParameters objectAtIndex:1] floatValue],
                            [[trimmedParameters objectAtIndex:2] floatValue],
                            [[trimmedParameters objectAtIndex:3] floatValue],
                            [[trimmedParameters objectAtIndex:4] floatValue],
                            [[trimmedParameters objectAtIndex:5] floatValue]
                            
                                                                                );
					result = CGAffineTransformConcat(specificTransform, result);
				}
				else
				{
					failed = YES;
				}
			}
			else if([anOperation hasPrefix:@"translate"])
			{
				CGFloat	xTrans = 0.0, yTrans = 0.0;
				switch([trimmedParameters count])
				{
					default:
					case 0:
					{
						failed = YES;
					}
                        break;
					case 2:
					{
						yTrans = [[trimmedParameters objectAtIndex:1] floatValue];
					}// deliberate fallthrough
					case 1:
					{
						xTrans = [[trimmedParameters objectAtIndex:0] floatValue];
					}
                    break;
				}
				result = CGAffineTransformTranslate(result, xTrans, yTrans);
			}
			else if([anOperation hasPrefix:@"scale"])
			{
				CGFloat	xScale = 1.0, yScale = 1.0;
				switch([trimmedParameters count])
				{
					default:
					case 0:
					{
						failed = YES;
					}
                        break;
					case 2:
					{
						yScale = [[trimmedParameters objectAtIndex:1] floatValue];
						xScale = [[trimmedParameters objectAtIndex:0] floatValue];
					}
                        break;
					case 1:
					{
						yScale = xScale = [[trimmedParameters objectAtIndex:0] floatValue];
					}
                        break;
				}
				result = CGAffineTransformScale(result, xScale, yScale);
			}
			else if([anOperation hasPrefix:@"rotate"])
			{
				CGFloat	rotationAngle = 0.0;
				switch([trimmedParameters count])
				{
					default:
					case 0:
					{
						failed = YES;
					}
                        break;
					case 3:
					{
						CGFloat centerX = [[trimmedParameters objectAtIndex:1] floatValue];
						CGFloat centerY = [[trimmedParameters objectAtIndex:2] floatValue];
						
						rotationAngle = [[trimmedParameters objectAtIndex:0] floatValue]*kDegreesToRadiansConstant;
						
						result = CGAffineTransformTranslate(result,centerX, centerY);
						result = CGAffineTransformRotate(result, rotationAngle);
						result = CGAffineTransformTranslate(result,-1.0f*centerX, -1.0f*centerY);
					}
                        break;
					case 1:
					{
						rotationAngle = [[trimmedParameters objectAtIndex:0] floatValue]*kDegreesToRadiansConstant;
						result = CGAffineTransformRotate(result, rotationAngle);
					}
                        break;
				}
			}
			else if([anOperation hasPrefix:@"skewX"])
			{
				switch([trimmedParameters count])
				{
					default:
					case 0:
					{
						failed = YES;
					}
                        break;
					case 1:
					{
						CGFloat skewAngleDegrees = [[trimmedParameters objectAtIndex:0] floatValue];
						double skewAngle = skewAngleDegrees*M_PI/180.0;
						double	tanSkewAngle = tan(skewAngle);
						CGAffineTransform skewedTransform = CGAffineTransformIdentity;
						skewedTransform.c = (CGFloat)tanSkewAngle;
						
						result = CGAffineTransformConcat(skewedTransform, result);
					}
                        break;
				}
			}
			else if([anOperation hasPrefix:@"skewY"])
			{
				switch([trimmedParameters count])
				{
					default:
					case 0:
					{
						failed = YES;
					}
                        break;
					case 1:
					{
						CGFloat skewAngleDegrees = [[trimmedParameters objectAtIndex:0] floatValue];
						double skewAngle = skewAngleDegrees*M_PI/180.0;
						double	tanSkewAngle = tan(skewAngle);
						
						CGAffineTransform skewedTransform = CGAffineTransformIdentity;
						skewedTransform.b = tanSkewAngle;
						result = CGAffineTransformConcat(skewedTransform, result);
					}
                        break;
				}
			}
            
			if(failed)
			{
				break;
			}
		}
	}
    
    
    
	return result;
}


NSString* MorphColorString(NSString* oldSVGColorString, NSString* newSVGColorString, CGFloat fractionThere)
{
    NSString* result = newSVGColorString;
    if(fractionThere <= 0.0)
    {
        result = oldSVGColorString;
    }
    else if(fractionThere < 1.0)
    {
        if([oldSVGColorString isEqualToString:@"inherited"]
           || [oldSVGColorString isEqualToString:@"currentColor"]
           || [newSVGColorString isEqualToString:@"inherited"]
           || [newSVGColorString isEqualToString:@"currentColor"]
           || IsStringURL(newSVGColorString)
           || IsStringURL(oldSVGColorString))
        {
        }
        else
        {
            UIColor* oldColor = UIColorFromSVGColorString(oldSVGColorString);
            UIColor* newColor = UIColorFromSVGColorString(newSVGColorString);
            CGFloat oldRed, oldGreen, oldBlue, oldAlpha;
            CGFloat newRed, newGreen, newBlue, newAlpha;
            if([oldColor getRed:&oldRed green:&oldGreen blue:&oldBlue alpha:&oldAlpha]
               && [newColor getRed:&newRed green:&newGreen blue:&newBlue alpha:&newAlpha])
            {
                CGFloat morphedRed = oldRed+(newRed-oldRed)*fractionThere;
                CGFloat morphedGreen = oldGreen+(newGreen-oldGreen)*fractionThere;
                CGFloat morphedBlue = oldBlue+(newBlue-oldBlue)*fractionThere;
                
                unsigned int morphedRedInt = (255.0*morphedRed);
                unsigned int morphedGreenInt = (255.0*morphedGreen);
                unsigned int morphedBlueInt = (255.0*morphedBlue);
                
                result = [NSString stringWithFormat:@"rgb(%d,%d,%d)",morphedRedInt, morphedGreenInt, morphedBlueInt];
            }
        }
    }
    return result;
}

NSDictionary<NSString*, NSString*>* WebNameMapping()
{
    static NSDictionary<NSString*, NSString*>* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        NSDictionary<NSString*, NSString*>* htmlColorMap =
        @{@"aliceblue":@"#f0f8ff",
          @"antiquewhite":@"#faebd7",
          @"aqua":@"#00ffff",
          @"aquamarine":@"#7fffd4",
          @"azure":@"#f0ffff",
          @"beige":@"#f5f5dc",
          @"bisque":@"#ffe4c4",
          @"black":@"#000000",
          @"blanchedalmond":@"#ffebcd",
          @"blue":@"#0000ff",
          @"blueviolet":@"#8a2be2",
          @"brown":@"#a52a2a",
          @"burlywood":@"#deb887",
          @"cadetblue":@"#5f9ea0",
          @"chartreuse":@"#7fff00",
          @"chocolate":@"#d2691e",
          @"coral":@"#ff7f50",
          @"cornflowerblue":@"#6495ed",
          @"cornsilk":@"#fff8dc",
          @"crimson":@"#dc143c",
          @"cyan":@"#00ffff",
          @"darkblue":@"#00008b",
          @"darkcyan":@"#008b8b",
          @"darkgoldenrod":@"#b8860b",
          @"darkgray":@"#a9a9a9",
          @"darkgrey":@"#a9a9a9",
          @"darkgreen":@"#006400",
          @"darkkhaki":@"#bdb76b",
          @"darkmagenta":@"#8b008b",
          @"darkolivegreen":@"#556b2f",
          @"darkorange":@"#ff8c00",
          @"darkorchid":@"#9932cc",
          @"darkred":@"#8b0000",
          @"darksalmon":@"#e9967a",
          @"darkseagreen":@"#8fbc8f",
          @"darkslateblue":@"#483d8b",
          @"darkslategray":@"#2f4f4f",
          @"darkslategrey":@"#2f4f4f",
          @"darkturquoise":@"#00ced1",
          @"darkviolet":@"#9400d3",
          @"deeppink":@"#ff1493",
          @"deepskyblue":@"#00bfff",
          @"dimgray":@"#696969",
          @"dimgrey":@"#696969",
          @"dodgerblue":@"#1e90ff",
          @"firebrick":@"#b22222",
          @"floralwhite":@"#fffaf0",
          @"forestgreen":@"#228b22",
          @"fuchsia":@"#ff00ff",
          @"gainsboro":@"#dcdcdc",
          @"ghostwhite":@"#f8f8ff",
          @"gold":@"#ffd700",
          @"goldenrod":@"#daa520",
          @"gray":@"#808080",
          @"grey":@"#808080",
          @"green":@"#008000",
          @"greenyellow":@"#adff2f",
          @"honeydew":@"#f0fff0",
          @"hotpink":@"#ff69b4",
          @"indianred":@"#cd5c5c",
          @"indigo":@"#4b0082",
          @"ivory":@"#fffff0",
          @"khaki":@"#f0e68c",
          @"lavender":@"#e6e6fa",
          @"lavenderblush":@"#fff0f5",
          @"lawngreen":@"#7cfc00",
          @"lemonchiffon":@"#fffacd",
          @"lightblue":@"#add8e6",
          @"lightcoral":@"#f08080",
          @"lightcyan":@"#e0ffff",
          @"lightgoldenrodyellow":@"#fafad2",
          @"lightgray":@"#d3d3d3",
          @"lightgrey":@"#d3d3d3",
          @"lightgreen":@"#90ee90",
          @"lightpink":@"#ffb6c1",
          @"lightsalmon":@"#ffa07a",
          @"lightseagreen":@"#20b2aa",
          @"lightskyblue":@"#87cefa",
          @"lightslategray":@"#778899",
          @"lightslategrey":@"#778899",
          @"lightsteelblue":@"#b0c4de",
          @"lightyellow":@"#ffffe0",
          @"lime":@"#00ff00",
          @"limegreen":@"#32cd32",
          @"linen":@"#faf0e6",
          @"magenta":@"#ff00ff",
          @"maroon":@"#800000",
          @"mediumaquamarine":@"#66cdaa",
          @"mediumblue":@"#0000cd",
          @"mediumorchid":@"#ba55d3",
          @"mediumpurple":@"#9370db",
          @"mediumseagreen":@"#3cb371",
          @"mediumslateblue":@"#7b68ee",
          @"mediumspringgreen":@"#00fa9a",
          @"mediumturquoise":@"#48d1cc",
          @"mediumvioletred":@"#c71585",
          @"midnightblue":@"#191970",
          @"mintcream":@"#f5fffa",
          @"mistyrose":@"#ffe4e1",
          @"moccasin":@"#ffe4b5",
          @"navajowhite":@"#ffdead",
          @"navy":@"#000080",
          @"oldlace":@"#fdf5e6",
          @"olive":@"#808000",
          @"olivedrab":@"#6b8e23",
          @"orange":@"#ffa500",
          @"orangered":@"#ff4500",
          @"orchid":@"#da70d6",
          @"palegoldenrod":@"#eee8aa",
          @"palegreen":@"#98fb98",
          @"paleturquoise":@"#afeeee",
          @"palevioletred":@"#db7093",
          @"papayawhip":@"#ffefd5",
          @"peachpuff":@"#ffdab9",
          @"peru":@"#cd853f",
          @"pink":@"#ffc0cb",
          @"plum":@"#dda0dd",
          @"powderblue":@"#b0e0e6",
          @"purple":@"#800080",
          @"rebeccapurple":@"#663399",
          @"red":@"#ff0000",
          @"rosybrown":@"#bc8f8f",
          @"royalblue":@"#4169e1",
          @"saddlebrown":@"#8b4513",
          @"salmon":@"#fa8072",
          @"sandybrown":@"#f4a460",
          @"seagreen":@"#2e8b57",
          @"seashell":@"#fff5ee",
          @"sienna":@"#a0522d",
          @"silver":@"#c0c0c0",
          @"skyblue":@"#87ceeb",
          @"slateblue":@"#6a5acd",
          @"slategray":@"#708090",
          @"slategrey":@"#708090",
          @"snow":@"#fffafa",
          @"springgreen":@"#00ff7f",
          @"steelblue":@"#4682b4",
          @"tan":@"#d2b48c",
          @"teal":@"#008080",
          @"thistle":@"#d8bfd8",
          @"tomato":@"#ff6347",
          @"turquoise":@"#40e0d0",
          @"violet":@"#ee82ee",
          @"wheat":@"#f5deb3",
          @"white":@"#ffffff",
          @"whitesmoke":@"#f5f5f5",
          @"yellow":@"#ffff00",
          @"yellowgreen":@"#9acd32",
          };
        sResult = [htmlColorMap copy];
    });
    return sResult;
}

UIColor* UIColorFromWebName(NSString* stringToConvert)
{
    NSDictionary<NSString*, NSString*>* colorMap = WebNameMapping();
    UIColor* result = nil;
    NSString* colorRGBString = [colorMap valueForKey:stringToConvert.lowercaseString];
    if(colorRGBString.length)
    {
        result = UIColorFromSVGColorString(colorRGBString); // this will be a mild recursion
    }
    
    return result;
}

UIColor* UIColorFromSVGColorString (NSString * stringToConvert)
{
    
    static NSCache* sCache = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sCache = [[NSCache alloc] init];
        sCache.name = @"Color Cache";
    });
    
    UIColor* result = [sCache objectForKey:stringToConvert];
    if(result == nil)
    {
        NSString *cString = [stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // strip 0X if it appears
        unsigned int r = 0, g = 0, b = 0;
        CGFloat alpha = 1.0;
        if ([cString hasPrefix:@"#"])
        {
            cString = [cString substringFromIndex:1];
            
            // Separate into r, g, b substrings
            NSRange range;
            NSString *rString = nil;
            NSString *gString = nil;
            NSString *bString = nil;
            NSUInteger stringLength = [cString length];
            if(stringLength == 3)
            {
                NSMutableString* mutableCString = [NSMutableString stringWithString:cString];
                [mutableCString insertString:[mutableCString substringWithRange:NSMakeRange(0, 1)] atIndex:1];
                [mutableCString insertString:[mutableCString substringWithRange:NSMakeRange(2, 1)] atIndex:3];
                [mutableCString insertString:[mutableCString substringWithRange:NSMakeRange(4, 1)] atIndex:5];
                cString = mutableCString;
                stringLength = 6;
            }
            if(stringLength >= 2)
            {
                range.location = 0;
                range.length = 2;
                
                rString = [cString substringWithRange:range];
            }
            
            if(stringLength >= 4)
            {
                range.location = 2;
                gString = [cString substringWithRange:range];
            }
            
            if(stringLength >= 6)
            {
                range.location = 4;
                bString = [cString substringWithRange:range];
            }
            if(gString == nil)
            {
                gString = rString;
            }
            if(bString == nil)
            {
                bString = gString;
            }
            if(rString != nil)
            {
                // Scan values
                [[NSScanner scannerWithString:rString] scanHexInt:&r];
                [[NSScanner scannerWithString:gString] scanHexInt:&g];
                [[NSScanner scannerWithString:bString] scanHexInt:&b];
            }
        }
        else if([stringToConvert hasPrefix:@"rgb"] || [stringToConvert hasPrefix:@"RGB"])
        {
            NSString*	trimmedString = [stringToConvert stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"()"] invertedSet]];
            if([trimmedString length])
            {
                trimmedString = [trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"()"]];
                
                NSArray* components = [trimmedString componentsSeparatedByString:@","];
                NSString*	redString = nil;
                NSString*	greenString = nil;
                NSString*	blueString = nil;
                NSUInteger	countOfComponents = [components count];
                if(countOfComponents > 0)
                {
                    redString = [[components objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if(countOfComponents > 1)
                {
                    greenString = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if(countOfComponents > 2)
                {
                    blueString = [[components objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if(greenString == nil) greenString = redString;
                if(blueString == nil) blueString = greenString;
                
                if([redString hasSuffix:@"%"])
                {
                    r = (unsigned int)(2.55001*[redString doubleValue]);
                }
                else
                {
                    r = [redString intValue];
                }
                if([greenString hasSuffix:@"%"])
                {
                    g = (unsigned int)(2.55*[greenString doubleValue]);
                }
                else
                {
                    g = [greenString intValue];
                }
                if([blueString hasSuffix:@"%"])
                {
                    b = (unsigned int)(2.55*[blueString doubleValue]);
                }
                else
                {
                    b = [blueString intValue];
                }
            }
        }
        else
        {
            if([stringToConvert isEqualToString:@"black"])
            {
                r = 0;
                g = 0;
                b = 0;
            }
            else if([stringToConvert isEqualToString:@"white"])
            {
                r = 255;
                g = 255;
                b = 255;
            }
            else if([stringToConvert isEqualToString:@"none"] || [stringToConvert isEqualToString:@"transparent"])
            { // I've been told that sometimes web developers will use 'transparent' then the more proper color is 'none'
                return [UIColor clearColor];
            }
            else if([stringToConvert isEqualToString:@"ActiveBorder"])
            {
                result = [UIColor greenColor];
            }
            else if([stringToConvert isEqualToString:@"ActiveCaption"])
            {
                result = [UIColor greenColor];
            }
            else if([stringToConvert isEqualToString:@"ButtonFace"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ButtonHighlight"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ButtonShadow"])
            {
            }
            else if([stringToConvert isEqualToString:@"ButtonText"])
            {
            }
            else if([stringToConvert isEqualToString:@"CaptionText"])
            {
            }
            else if([stringToConvert isEqualToString:@"GrayText"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"Highlight"])
            {
            }
            else if([stringToConvert isEqualToString:@"HighlightText"])
            {
                result = [UIColor whiteColor];
            }
            else if([stringToConvert isEqualToString:@"InactiveBorder"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"InactiveCaption"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"InactiveCaptionText"])
            {
            }
            else if([stringToConvert isEqualToString:@"InfoBackground"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"InfoText"])
            {
            }
            else if([stringToConvert isEqualToString:@"Menu"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"MenuText"])
            {
            }
            else if([stringToConvert isEqualToString:@"Scrollbar"])
            {
            }
            else if([stringToConvert isEqualToString:@"ThreeDDarkShadow"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ThreeDFace"])
            {
                result = [UIColor lightGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ThreeDHighlight"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ThreeDLightShadow"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"ThreeDShadow"])
            {
                result = [UIColor darkGrayColor];
            }
            else if([stringToConvert isEqualToString:@"Window"])
            {
                result = [UIColor whiteColor];
            }
            else if([stringToConvert isEqualToString:@"WindowFrame"])
            {
            }
            else if([stringToConvert isEqualToString:@"WindowText"])
            {
            }
            else
            {
                NSString* lowerCaseStringToConvert = [stringToConvert lowercaseString];
                result = UIColorFromWebName(lowerCaseStringToConvert);
                if(result == nil)
                {
                    [sCache setObject:[NSNull null] forKey:stringToConvert cost:4];
                    return nil;
                }
            }
        }
        
        if(result == nil)
        {
            CGFloat	redF = (CGFloat) r / 255.0f;
            CGFloat	greenF =(CGFloat) g / 255.0f;
            CGFloat	blueF =(CGFloat) b / 255.0f;
            result = [UIColor colorWithRed:redF
                                     green:greenF
                                      blue:blueF
                                     alpha:alpha];
        }
        
        if(result != nil)
        {
            [sCache setObject:result forKey:stringToConvert cost:6];
        }
    }
    else if([result isKindOfClass:[NSNull class]])
    {
        result = nil;
    }
    
    
	return result;
}


CGRect SVGStringToRectSlow(NSString* serializedRect)
{
    CGRect	result  = CGRectZero;
	
	NSArray* components = [serializedRect	componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if([components count] == 4)
	{
		result = CGRectMake([[components objectAtIndex:0] floatValue],
							[[components objectAtIndex:1] floatValue],
							[[components objectAtIndex:2] floatValue],
							[[components objectAtIndex:3] floatValue]);
	}
	return result;
}

CGRect SVGStringToRect(NSString* serializedRect)
{
    CGRect	result  = CGRectZero;
    NSInteger stringLength = serializedRect.length;
    if(stringLength >= 7 && stringLength < 255)
    {
        NSInteger stringIndex = 0;
        char stringBuffer[256]; // YES. I should learn Regular Expressions.
        char numberBuffer[256];
        if([serializedRect  getCString:stringBuffer maxLength:255 encoding:NSASCIIStringEncoding])
        {
            while(stringIndex < stringLength)
            {
                char aChar = stringBuffer[stringIndex];
                if(aChar == '-' || aChar == '.' || (aChar >= '0' && aChar <= '9'))
                {
                    break;
                }
                else
                {
                    stringIndex++;
                }
            }
            if((stringLength-stringIndex) >= 7)
            {
                float parameters[4];
                NSUInteger parameterIndex = 0;
                BOOL failed = NO;
                while(stringIndex < stringLength && !failed && parameterIndex < 4)
                {
                    char aChar = stringBuffer[stringIndex];
                    
                    NSInteger beginNumberIndex = -1;
                    BOOL numberSeen = NO;
                    BOOL periodSeen = NO;
                    while(beginNumberIndex == -1 && stringIndex < stringLength)
                    {
                        if(aChar == '-')
                        {
                            beginNumberIndex = stringIndex++;
                        }
                        else if(aChar == '.')
                        {
                            beginNumberIndex = stringIndex++;
                            periodSeen = YES;
                        }
                        else if(aChar >= '0' && aChar <= '9')
                        {
                            beginNumberIndex = stringIndex++;
                            numberSeen = YES;
                        }
                        else
                        {
                            stringIndex++;
                        }
                        aChar = stringBuffer[stringIndex];
                    }
                    
                    if(beginNumberIndex > -1)
                    {
                        NSInteger endNumIndex = beginNumberIndex;
                        while(stringIndex < stringLength)
                        {
                            aChar = stringBuffer[stringIndex++];
                            if(aChar >= '0' && aChar <= '9')
                            {
                                numberSeen = YES;
                                endNumIndex++;
                            }
                            else if(aChar == '.' && !periodSeen)
                            {
                                periodSeen = YES;
                                endNumIndex++;
                            }
                            else
                            {
                                break;
                            }
                        }
                        if(numberSeen)
                        {
                            memcpy(numberBuffer, &stringBuffer[beginNumberIndex], endNumIndex-beginNumberIndex+1);
                            numberBuffer[endNumIndex-beginNumberIndex+1]= 0;
                            if(periodSeen)
                            {
                                parameters[parameterIndex++]  = atof(numberBuffer);
                            }
                            else
                            {
                                parameters[parameterIndex++]  = atoi(numberBuffer);
                            }
                        }
                        else
                        {
                            failed = YES;
                        }
                    }
                    else
                    {
                        failed = YES;
                    }
                }
                
                if(!failed)
                {
                    result = CGRectMake(parameters[0], parameters[1], parameters[2], parameters[3]);
                }
                
            }
        }
    }

    return result;
}



CGFloat	GetNextCoordinate(const char* buffer, NSUInteger* indexPtr, NSUInteger bufferLength, BOOL* failed)
{ // retrieve the next value from the d parameter of an SVG path
	CGFloat	result = 0.0;
	NSUInteger	srcBufferIndex = *indexPtr;
	char	theChar = 0;
    BOOL numberSeen = NO;
    
    if(srcBufferIndex < bufferLength)
    {
        theChar = buffer[srcBufferIndex];
        if((theChar >= '0' && theChar <= '9') || theChar == '-' || theChar == '.' || theChar == '+' || theChar == ' ' || theChar == '\n' || theChar == 'e')
        {
            srcBufferIndex++;
        }
        else
        {
            *failed = YES;
        }
    }
    else
    {
        *failed = YES;
    }
	
	while(*failed == NO && !(theChar == '-' || theChar == '+' || theChar == '.' || (theChar >= '0' && theChar <= '9') || theChar == 'e'))
	{
        if(srcBufferIndex < bufferLength)
        {
            theChar = buffer[srcBufferIndex];
            if((theChar >= '0' && theChar <= '9') || theChar == '-' || theChar == '.' || theChar == '+' || theChar == ' ' || theChar == '\n')
            {
                srcBufferIndex++;
            }
            else
            {
                *failed = YES;
            }
        }
        else
        {
            *failed = YES;
        }
		if(srcBufferIndex >= bufferLength)
		{
			break;
		}
	}
	if(*failed == NO)
    {
        char	stringBuffer[100];
        NSUInteger	stringBufferIndex = 0;
        
        if(theChar == '-' || theChar == '+' || theChar == '.' || (theChar >= '0' && theChar <= '9') || theChar == 'e')
        {
            stringBuffer[stringBufferIndex++] = theChar;
            numberSeen = (theChar >= '0' && theChar <= '9');
        }
        BOOL periodSeen = NO, expSeen = NO;
        while(srcBufferIndex < bufferLength)
        {
            theChar = buffer[srcBufferIndex];
            if((theChar == '.' && !periodSeen)
               || (theChar >= '0' && theChar <= '9') || theChar == 'e' || (expSeen && (theChar == '-' || theChar == '+')))
            {
                if(theChar == '.')
                {
                    periodSeen = YES;
                }
                else if(theChar >= '0' && theChar <= '9')
                {
                    numberSeen = YES;
                }
                else if(theChar == 'e')
                {
                    expSeen = YES;
                }
                srcBufferIndex++;
                stringBuffer[stringBufferIndex++] = theChar;
                if(stringBufferIndex > 98)
                {
                    NSLog(@"Path number way too long:%s", stringBuffer);
                    break;
                }
            }
            else
            {
                break;
            }
        }
        if(stringBufferIndex > 0 && numberSeen)
        {
            stringBuffer[stringBufferIndex++] = 0;
            char* endPtr = &stringBuffer[stringBufferIndex];
            if(periodSeen || expSeen)
            {
                result = strtof(stringBuffer, &endPtr);
            }
            else
            {
                result = strtol(stringBuffer, &endPtr, 10);
            }
        }
        else if(srcBufferIndex >= bufferLength)
        {
            *failed = YES;
        }
        
        while(srcBufferIndex < bufferLength && 
              !((theChar >= 'a' && theChar <= 'z') || (theChar >= 'A' && theChar <= 'Z')
                || theChar == '-' || theChar == '+' || theChar == '.' || (theChar >= '0' && theChar <= '9') || theChar == 'e'))
        { // jump to the next operand or number
            theChar = buffer[++srcBufferIndex];
        }
	}
	*indexPtr = srcBufferIndex;
	return result;
}


NSString* SVGArcFromSensibleParameters(CGFloat xRadius, CGFloat yRadius, double xAxisRotationDegrees,
                                       double startAngle, double endAngle)
{
    NSString* result = nil;
    double deltaAngle = endAngle-startAngle;
    if(deltaAngle == 360.0)
    {
        NSString* firstPortion = SVGArcFromSensibleParameters(xRadius, yRadius, xAxisRotationDegrees, startAngle, endAngle-0.5);
        NSString* secondPortion = @" Z";
        result = [firstPortion stringByAppendingString:secondPortion];
    }
    else if(deltaAngle == -360.0)
    {
        NSString* firstPortion = SVGArcFromSensibleParameters(xRadius, yRadius, xAxisRotationDegrees, startAngle, endAngle+0.5);
        NSString* secondPortion = @" Z";
        result = [firstPortion stringByAppendingString:secondPortion];
    }
    else
    {
        // this will be relative to 0,0
        NSMutableString* mutableResult = [[NSMutableString alloc] initWithCapacity:100];
        
        
        int arcFlag = (fabs(deltaAngle) > 180)?1:0;
        int sweepFlag = (deltaAngle > 0)?1:0;
        
        double cosAxisRotation = cos(xAxisRotationDegrees*M_PI/180.0);
        double sinAxisRotation = sin(xAxisRotationDegrees*M_PI/180.0);
        double cosStartAngle = cos(startAngle*M_PI/180.0);
        double sinStartAngle = sin(startAngle*M_PI/180.0);
        double cosEndAngle = cos(endAngle*M_PI/180.0);
        double sinEndAngle = sin(endAngle*M_PI/180.0);
        
        
        double  centerX = (cosAxisRotation*xRadius*cosStartAngle-sinAxisRotation*yRadius*sinStartAngle);
        double  centerY = (sinAxisRotation*xRadius*cosStartAngle+cosAxisRotation*yRadius*sinStartAngle);
        
        double deltaX = centerX-(cosAxisRotation*xRadius*cosEndAngle-sinAxisRotation*yRadius*sinEndAngle);
        double deltaY = +centerY-(sinAxisRotation*xRadius*cosEndAngle+cosAxisRotation*yRadius*sinEndAngle);
        
        if(fabs(deltaX) < 0.000001)
        {
            deltaX= 0.0;
        }
        if(fabs(deltaY) < 0.0000001)
        {
            deltaY = 0.0;
        }
        
        [mutableResult appendFormat:@"a %0.0f %0.0f %0.0f %d %d %0.2lf %0.2lf", xRadius, yRadius, xAxisRotationDegrees, arcFlag, sweepFlag, deltaX, deltaY];
        
        
        
        result = [mutableResult copy];
    }
    return result;
}

void AddSVGArcToPath(CGMutablePathRef thePath,
                     CGFloat xRadius,
                     CGFloat  yRadius,
                     double  xAxisRotationDegrees,
                     BOOL largeArcFlag, BOOL	sweepFlag,
                     CGFloat endPointX, CGFloat endPointY)
{//implementation notes http://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter
	// general algorithm from MIT licensed http://code.google.com/p/svg-edit/source/browse/trunk/editor/canvg/canvg.js
	// Gabe Lerner (gabelerner@gmail.com)
	// first do first aid to the parameters to keep them in line
	
	CGPoint curPoint = CGPathGetCurrentPoint(thePath);
	if(curPoint.x == endPointX && endPointY == curPoint.y)
	{ // do nothing
	}
	else if(xRadius == 0.0 || yRadius == 0.0) // not an actual arc, draw a line segment
	{
		CGPathAddLineToPoint(thePath,NULL, endPointX, endPointY);
	}
	else // actually try to draw an arc
	{
		xRadius = fabs(xRadius); // make sure radius are positive
		yRadius = fabs(yRadius);
		xAxisRotationDegrees = fmod(xAxisRotationDegrees, 360.0);
		CGFloat	xAxisRotationRadians = xAxisRotationDegrees*kDegreesToRadiansConstant;
		CGFloat cosineAxisRotation = cosf(xAxisRotationRadians);
		CGFloat sineAxisRotation = sinf(xAxisRotationRadians);
		CGFloat deltaX = curPoint.x-endPointX;
		CGFloat deltaY = curPoint.y-endPointY;
		
		// steps are from the implementation notes
		// F.6.5  Step 1: Compute (x1′, y1′)
		CGPoint	translatedCurPoint
        = CGPointMake(cosineAxisRotation*deltaX/2.0f+sineAxisRotation*deltaY/2.0f,
                      -1.0f*sineAxisRotation*deltaX/2.0f+cosineAxisRotation*deltaY/2.0f);
		
        
		// (skipping to different section) F.6.6 Step 3: Ensure radii are large enough
		CGFloat	shouldBeNoMoreThanOne = translatedCurPoint.x*translatedCurPoint.x/(xRadius*xRadius)
        + translatedCurPoint.y*translatedCurPoint.y/(yRadius*yRadius);
		if(shouldBeNoMoreThanOne > 1.0)
		{
			xRadius *= sqrtf(shouldBeNoMoreThanOne);
			yRadius *= sqrtf(shouldBeNoMoreThanOne);
			
			shouldBeNoMoreThanOne = translatedCurPoint.x*translatedCurPoint.x/(xRadius*xRadius)
			+ translatedCurPoint.y*translatedCurPoint.y/(yRadius*yRadius);
			if(shouldBeNoMoreThanOne > 1.0) // sometimes just a bit north of 1.0000000 after first pass
			{
				shouldBeNoMoreThanOne += .000001; // making sure
				xRadius *= sqrtf(shouldBeNoMoreThanOne);
				yRadius *= sqrtf(shouldBeNoMoreThanOne);
			}
		}
		
		CGAffineTransform	transform = CGAffineTransformIdentity;
		// back to  F.6.5   Step 2: Compute (cx′, cy′)
		double  centerScalingDivisor = xRadius*xRadius*translatedCurPoint.y*translatedCurPoint.y
        + yRadius*yRadius*translatedCurPoint.x*translatedCurPoint.x;
		double	centerScaling = 0.0;
		
		if(centerScalingDivisor != 0.0)
		{
			centerScaling = sqrt((xRadius*xRadius*yRadius*yRadius
                                  - xRadius*xRadius*translatedCurPoint.y*translatedCurPoint.y
                                  - yRadius*yRadius*translatedCurPoint.x*translatedCurPoint.x)
								 / centerScalingDivisor);
            if(centerScaling != centerScaling)
            {
                centerScaling = 0.0;
            }
			if(largeArcFlag == sweepFlag)
			{
				centerScaling *= -1.0;
			}
		}
		
		CGPoint translatedCenterPoint = CGPointMake(centerScaling*xRadius*translatedCurPoint.y/yRadius,
                                                    -1.0f*centerScaling*yRadius*translatedCurPoint.x/xRadius);
		
		// F.6.5  Step 3: Compute (cx, cy) from (cx′, cy′)
		CGPoint centerPoint
        = CGPointMake((curPoint.x+endPointX)/2.0f+cosineAxisRotation*translatedCenterPoint.x-sineAxisRotation*translatedCenterPoint.y,
                      (curPoint.y+endPointY)/2.0f+sineAxisRotation*translatedCenterPoint.x+cosineAxisRotation*translatedCenterPoint.y);
		// F.6.5   Step 4: Compute θ1 and Δθ
		
		// misusing CGPoint as a vector
		CGPoint vectorX = CGPointMake(1.0, 0.0);
		CGPoint vectorU = CGPointMake((translatedCurPoint.x-translatedCenterPoint.x)/xRadius,
									  (translatedCurPoint.y-translatedCenterPoint.y)/yRadius);
		CGPoint vectorV = CGPointMake((-1.0f*translatedCurPoint.x-translatedCenterPoint.x)/xRadius,
									  (-1.0f*translatedCurPoint.y-translatedCenterPoint.y)/yRadius);
		
		CGFloat	startAngle = CalculateVectorAngle(vectorX, vectorU);
		CGFloat	angleDelta = CalculateVectorAngle(vectorU, vectorV);
		CGFloat vectorRatio = CalculateVectorRatio(vectorU, vectorV);
		if(vectorRatio <= -1)
		{
			angleDelta = M_PI;
		}
		else if(vectorRatio >= 1.0)
		{
			angleDelta = 0.0;
		}
		
		if (sweepFlag == 0 && angleDelta > 0.0)
		{
			angleDelta = angleDelta - 2.0 * M_PI;
		}
		if (sweepFlag == 1 && angleDelta < 0.0)
		{
			angleDelta = angleDelta + 2.0 * M_PI;
		}
		
		transform = CGAffineTransformTranslate(transform,
											   centerPoint.x, centerPoint.y);
		
		transform = CGAffineTransformRotate(transform, xAxisRotationRadians);
		
		CGFloat radius = (xRadius > yRadius) ? xRadius : yRadius;
		CGFloat scaleX = (xRadius > yRadius) ? 1.0 : xRadius / yRadius;
		CGFloat scaleY = (xRadius > yRadius) ? yRadius / xRadius : 1.0;
		
		transform = CGAffineTransformScale(transform, scaleX, scaleY);
		
		CGPathAddArc(thePath, &transform, 0.0, 0.0, radius, startAngle, startAngle+angleDelta,
					 !sweepFlag); 
	}
}

@implementation SVGToQuartz

+(void) LogQuartzContextState:(CGContextRef)quartzContext
{
    if(quartzContext == NULL)
    {
        NSLog(@"Expected Non-Null CGContextRef");
    }
    else
    {
        NSLog(@"**Begin CGContextRef**");
        CGAffineTransform transform = CGContextGetCTM(quartzContext);
        NSString* transformString = CGAffineTransformToSVGTransform(transform);
        NSLog(@"\tTransform = %@", transformString);
        if(CGContextIsPathEmpty(quartzContext))
        {
            NSLog(@"\tHas Path = NO");
        }
        else
        {
            NSLog(@"\tHas Path = YES");
            
            CGPoint pathPoint = CGContextGetPathCurrentPoint(quartzContext);
            
            NSLog(@"\tPath Point x=%lf, y=%lf", pathPoint.x, pathPoint.y);
            CGRect pathBoundingRect = CGContextGetPathBoundingBox(quartzContext);
            NSLog(@"\tPath Bounds = {%lf, %lf, %lf, %lf}", pathBoundingRect.origin.x, pathBoundingRect.origin.y, pathBoundingRect.size.width, pathBoundingRect.size.height);
            
        }
        
        CGRect clipBoundingRect = CGContextGetClipBoundingBox(quartzContext);
        NSLog(@"\tClip Bounds = {%lf, %lf, %lf, %lf}", clipBoundingRect.origin.x, clipBoundingRect.origin.y, clipBoundingRect.size.width, clipBoundingRect.size.height);
        
        
        CGPoint textPoint= CGContextGetTextPosition(quartzContext);
        
        NSLog(@"\tText Point x=%lf, y=%lf", textPoint.x, textPoint.y);
        
        transform = CGContextGetTextMatrix(quartzContext);
        transformString = CGAffineTransformToSVGTransform(transform);
        NSLog(@"\tText Transform = %@", transformString);
        
        
        
        transform = CGContextGetUserSpaceToDeviceSpaceTransform(quartzContext);
        transformString = CGAffineTransformToSVGTransform(transform);
        NSLog(@"\tUser Space Transform = %@", transformString);
        
        NSLog(@"**End CGContextRef**");
    }
}


+(BOOL)attributeHasDisplaySetToNone:(NSDictionary*)attributes
{
    BOOL result = NO;
    NSString* displayString = [attributes objectForKey:@"display"];
    if([displayString isEqualToString:@"none"])
    {
        result = YES;
    }
    return result;
}


+(CGRect) aspectRatioDrawRectFromString:(NSString*)preserveAspectRatioString givenBounds:(CGRect)viewRect
                            naturalSize:(CGSize)naturalSize
{
	CGRect result = viewRect;
	BOOL	sliceIt = NO;
	CGFloat		xMin = viewRect.origin.x;
	CGFloat		xMax = viewRect.origin.x+viewRect.size.width;
	CGFloat		yMin = viewRect.origin.y+viewRect.size.height ;
	CGFloat		yMax = viewRect.origin.y;
	
	CGFloat		xAnchor = xMin, yAnchor = yMin;
	
	NSArray* flavors = [preserveAspectRatioString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	for(NSString* aFlavor in flavors)
	{
		if([aFlavor isEqualToString:@"meet"])
		{
			sliceIt = NO;
		}
		else if ([aFlavor isEqualToString:@"slice"])
		{
			sliceIt = YES;
		}
		else if ([aFlavor isEqualToString:@"xMinYMin"])
		{
			xAnchor = xMin;
			yAnchor = yMin;
		}
		else if ([aFlavor isEqualToString:@"xMidYMin"])
		{
			xAnchor = (xMax-xMin)/2.0f;
			yAnchor = yMin;
		}
		else if ([aFlavor isEqualToString:@"xMaxYMin"])
		{
			xAnchor = xMax;
			yAnchor = yMin;
		}
		else if ([aFlavor isEqualToString:@"xMinYMid"])
		{
			xAnchor = xMin;
			yAnchor = (yMax-yMin)/2.0f;
		}
		else if ([aFlavor isEqualToString:@"xMidYMid"])
		{
			xAnchor = (xMax-xMin)/2.0f;
			yAnchor = (yMax-yMin)/2.0f;
		}
		else if ([aFlavor isEqualToString:@"xMaxYMid"])
		{
			xAnchor = xMax;
			yAnchor = (yMax-yMin)/2.0f;
		}
		else if ([aFlavor isEqualToString:@"xMinYMax"])
		{
			xAnchor = xMin;
			yAnchor = yMax;
		}
		else if ([aFlavor isEqualToString:@"xMidYMax"])
		{
			xAnchor = (xMax-xMin)/2.0f;
			yAnchor = yMax;
		}
		else if ([aFlavor isEqualToString:@"xMaxYMax"])
		{
			xAnchor = xMax;
			yAnchor = yMax;
		}
	}
	
	if(sliceIt)
	{
		result.size = naturalSize;
		if(xAnchor == xMax)
		{
			result.origin.x = xMax-naturalSize.width;
		}
		else if(xAnchor == xMin)
		{
			result.origin.x = xMin;
		}
		else
		{
			result.origin.x = (xMax-xMin)/2.0f-naturalSize.width/2.0f;
		}
		if(yAnchor == yMax)
		{
			result.origin.y = yMax;
		}
		else if(yAnchor == yMin)
		{
			result.origin.y = yMin-naturalSize.height;
		}
		else
		{
			result.origin.y = (yMin-yMax)/2.0f-naturalSize.height/2.0f;
		}
	}
	else
	{
		CGFloat naturalAspectRatio = naturalSize.width/naturalSize.height;
		CGFloat	viewAspectRatio = viewRect.size.width/viewRect.size.height;
		if(naturalAspectRatio >= viewAspectRatio)
		{ // extra space on top
			CGFloat	resultHeight = result.size.width/naturalAspectRatio;
			result.size.height = resultHeight;
			if(yAnchor == yMax)
			{
				result.origin.y = yMax;
			}
			else if(yAnchor == yMin)
			{
				result.origin.y = yMin - resultHeight;
			}
			else
			{
				result.origin.y = yMax+(viewRect.size.height-resultHeight)/2.0f;
			}
		}
		else
		{ // extra space on edges
			CGFloat	resultWidth = result.size.height*naturalAspectRatio;
			result.size.width = resultWidth;
			if(xAnchor == xMax)
			{
				result.origin.x = xMax - resultWidth;
			}
			else if(xAnchor == xMin)
			{
				result.origin.x = xMin;
			}
			else
			{
				result.origin.x = xMin+(viewRect.size.width-resultWidth)/2.0f;
			}
		}
	}
	
	return result;
}

+(void)imageAtXLinkPath:(NSString*)xLinkPath orAtRelativeFilePath:(NSString*)relativeFilePath withSVGContext:(id<SVGContext>)svgContext intoCallback:(handleRetrievedImage_t)retrievalCallback
{
    UIImage* result = nil;
    
	if([xLinkPath hasPrefix:@"data:image/"])
	{// embedded in the svg itself as a base 64
		NSString* metaDataString = [xLinkPath substringFromIndex:5];
		NSRange rangeOfSemicolon = [metaDataString rangeOfString:@";"];
		NSRange rangeOfComma = [metaDataString rangeOfString:@","];
		if(rangeOfSemicolon.location != NSNotFound && rangeOfComma.location != NSNotFound)
		{
			NSString* mimeString = [metaDataString substringToIndex:rangeOfSemicolon.location];
			NSString* encodingString = [metaDataString substringWithRange:NSMakeRange(rangeOfSemicolon.location+1,
                                                                                      rangeOfComma.location-rangeOfSemicolon.location-1)];
			if([encodingString isEqualToString:@"base64"]
			   && ([mimeString isEqualToString:@"image/jpg"] || [mimeString isEqualToString:@"image/png"]
                   || [mimeString isEqualToString:@"image/jpeg"]))
			{
				CGImageRef imageRef = 0;
				NSString*	dataString = [metaDataString substringFromIndex:rangeOfComma.location+1];
				NSData*	decodedData = DecodeBase64FromStringToData(dataString);
				CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef) decodedData);
				if(provider != 0)
				{
					if([mimeString isEqualToString:@"image/jpg"] || [mimeString isEqualToString:@"image/jpeg"])
					{
						imageRef = CGImageCreateWithJPEGDataProvider(provider, NULL, true,
                                                                     kColoringRenderingIntent);
					}
					else if([mimeString isEqualToString:@"image/png"])
					{
						imageRef = CGImageCreateWithPNGDataProvider(provider, NULL, true,
                                                                    kColoringRenderingIntent);
					}
                    else if([mimeString isEqualToString:@"image/tif"])
                    {
                    }
					CFRelease(provider);
				}
				if(imageRef != 0)
				{
					result = [[UIImage alloc] initWithCGImage:imageRef];
					CFRelease(imageRef);
				}
			}
		}
        retrievalCallback(result, nil);
	}
	else
	{
        NSURL*	fileURL = nil;
		if([relativeFilePath length] && xLinkPath.length)
		{
			xLinkPath = [relativeFilePath stringByAppendingPathComponent:xLinkPath];
            fileURL = [svgContext absoluteURL:xLinkPath];
		}
        else if(relativeFilePath)
        {
            xLinkPath = relativeFilePath;
            fileURL = [svgContext relativeURL:xLinkPath];
        }
        else if(xLinkPath.length)
        {
            fileURL = [NSURL fileURLWithPath:xLinkPath];
        }
        
		[GHImageCache retrieveCachedImageFromURL:fileURL intoCallback:^(UIImage *anImage, NSURL *location) {
            retrievalCallback(anImage, location);
        }];
	}
}



+(NSString*)styleAttributeStringForDictionary:(NSDictionary*)styleDictionary
{
    NSMutableString* mutableResult = [NSMutableString string];
    NSArray* allKeys = [styleDictionary allKeys];
    for(NSString* aKey in allKeys)
    {
        NSString* aValue = [styleDictionary valueForKey:aKey];
        if([aKey length] && [aValue length])
        {
            if([mutableResult length])
            {
                [mutableResult appendString:@";"];
            }
            [mutableResult appendFormat:@"%@:%@", aKey, aValue];
        }
    }
    return [mutableResult copy];
}


+(NSString*) valueForStyleAttribute:(NSString*)attributeName fromDefinition:(NSDictionary*)elementAttributes
{
	NSString* result = [elementAttributes objectForKey:attributeName];
	if(result == nil)
	{
		NSString*	styleString = [elementAttributes objectForKey:@"style"];
		if([styleString length])
		{
			NSArray* components = [styleString componentsSeparatedByString:@";"];
			if([components count])
			{
				NSString* prefix = [attributeName stringByAppendingString:@":"];
				for(NSString* aValuePairString in components)
				{
                    NSString* trimmedValuePairString = [aValuePairString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					if([trimmedValuePairString hasPrefix:prefix] && trimmedValuePairString.length > prefix.length)
					{
						result = [aValuePairString substringFromIndex:[prefix length]];
                        result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						break;
					}
				}
			}
		}
	}
	return result;
}

+(NSString*) valueForStyleAttribute:(NSString*)attributeName fromDefinition:(NSDictionary*)elementAttributes forEnityName:(NSString*)entityTypeName withSVGContext:(id<SVGContext> __nullable)svgContext
{
    NSString* result = nil;
    
    if(svgContext.hasCSSAttributes)
    {
        NSArray* classes = [[elementAttributes valueForKey:@"class"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        result = [svgContext attributeNamed:attributeName classes:classes entityName:entityTypeName];
    }
    
    if(result == nil)
    {
        result = [self valueForStyleAttribute:attributeName fromDefinition:elementAttributes];
    }
    
    return result;
}

+(NSDictionary*)dictionaryForStyleAttributeString:(NSString*)styleString
{
    NSArray* styleElements = [styleString componentsSeparatedByString:@";"];
    
    NSMutableDictionary* mutableResult = [[NSMutableDictionary alloc] initWithCapacity:[styleElements count]];
    for(NSString* aValuePairString in styleElements)
    {
        NSRange colonRange = [aValuePairString rangeOfString:@":"];
        NSUInteger stringLength = [aValuePairString length];
        if(stringLength>=3 && colonRange.location != NSNotFound && colonRange.location != 0
           && colonRange.location < stringLength-1)
        {
            NSString* name = [aValuePairString substringToIndex:colonRange.location];
            NSString* value = [aValuePairString substringFromIndex:colonRange.location+1];
            [mutableResult setValue:value forKey:name];
        }
    }
    
    return [mutableResult copy];
}

+(void) setupLineDashForQuartzContext:(CGContextRef)quartzContext withSVGDashArray:(NSString*)strokeDashString andPhase:(NSString*)phaseString
{
    if(strokeDashString != nil)
	{
		if([strokeDashString isEqualToString:@"none"]
		   || [strokeDashString isEqualToString:@"0"])
		{
			CGContextSetLineDash(quartzContext, 0.0, NULL, 0);
		}
		else
		{
			NSArray* dashElements = [strokeDashString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
			NSUInteger countOfElments = [dashElements count];
			if(countOfElments)
			{
				if(countOfElments & 1)
				{ // double it to make it even
					dashElements = [dashElements arrayByAddingObjectsFromArray:dashElements];
					countOfElments = [dashElements count];
				}
				CGFloat* dashes = malloc(sizeof(CGFloat)*countOfElments);
				NSUInteger	index = 0;
				for(; index < countOfElments; index++)
				{
					NSString* aDash = [[dashElements objectAtIndex:index] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					CGFloat		dashFloatValue = [aDash floatValue];
					dashes[index] = dashFloatValue;
				}
				CGFloat phase = 0.0;
				
				if(phaseString != nil)
				{
					phase = [phaseString floatValue];
				}
				CGContextSetLineDash(quartzContext, phase, dashes, countOfElments);
                free(dashes);
			}
		}
	}
}

+(void) setupLineWidthForQuartzContext:(CGContextRef)quartzContext withSVGStrokeString:(NSString*)strokeString withVectorEffect:(NSString*)vectorEffect withSVGContext:(id<SVGContext>)svgContext
{
    if(strokeString != nil)
    {
        CGFloat	strokeWidth = [strokeString floatValue];
        if([vectorEffect isEqualToString:@"non-scaling-stroke"])
        {
            CGSize convertedSize = CGContextConvertSizeToUserSpace(quartzContext,
                                                                   CGSizeMake(strokeWidth, strokeWidth));
            strokeWidth = (fabs(convertedSize.width)+fabs(convertedSize.height))/2.0;
            strokeWidth *= svgContext.explicitLineScaling;
        }
        
        CGContextSetLineWidth(quartzContext, strokeWidth);
    }
}


+(void) setupOpacityForQuartzContext:(CGContextRef)quartzContext withSVGOpacity:(NSString*)opacityString
{
    if(opacityString.length)
    {
        CGFloat	opacity = [opacityString floatValue];
        if(opacity >= 0 && opacity <= 1.0)
        {
            CGContextSetAlpha(quartzContext, opacity);
        }
    }
}

+(void) setupColorForQuartzContext:(CGContextRef)quartzContext withColorString:(NSString*)colorString withSVGContext:(id<SVGContext>)svgContext
{
    if([colorString length])
    {
        UIColor* colorToUse = nil;
        if(IsStringURL(colorString))
        {
            id aColor = [svgContext objectAtURL:colorString];
            if([aColor respondsToSelector:@selector(asColorWithSVGContext:)])
            {
                colorToUse = [aColor performSelector:@selector(asColorWithSVGContext:) withObject:svgContext];
            }
        }
        else if([colorString length])
        {
            colorToUse= [svgContext colorForSVGColorString:colorString];
        }
        if(colorToUse != nil)
        {
            CGContextSetFillColorWithColor(quartzContext, colorToUse.CGColor);
            CGContextSetStrokeColorWithColor(quartzContext, colorToUse.CGColor);
        }
    }
}

+(void)setupLineEndForQuartzContext:(CGContextRef)quartzContext withSVGLineEndString:(NSString*)lineCapString
{
    if(lineCapString != nil)
	{
		CGLineCap	lineCapType = kCGLineCapButt;
		if([lineCapString isEqualToString:@"butt"])
		{
		}
		else if([lineCapString isEqualToString:@"round"])
		{
			lineCapType = kCGLineCapRound;
		}
		else if([lineCapString isEqualToString:@"square"])
		{
			lineCapType = kCGLineCapSquare;
		}
		
		CGContextSetLineCap(quartzContext, lineCapType);
	}
}

+(void) setupMiterLimitForQuartzContext:(CGContextRef)quartzContext withSVGMiterLimitString:(NSString*)miterLimitString
{
    if(miterLimitString != nil)
	{
		CGFloat	miterLimit = [miterLimitString floatValue];
		CGContextSetMiterLimit(quartzContext, miterLimit);
	}
}

+(void)setupMiterForQuartzContext:(CGContextRef)quartzContext withSVGMiterString:(NSString*)lineJoinString
{
    if(lineJoinString.length)
    {
        CGLineJoin	lineJoinType = kCGLineJoinMiter;
        if([lineJoinString isEqualToString:@"miter"])
        {
        }
        else if([lineJoinString isEqualToString:@"round"])
        {
            lineJoinType = kCGLineJoinRound;
        }
        else if([lineJoinString isEqualToString:@"bevel"])
        {
            lineJoinType = kCGLineJoinBevel;
        }
        
        CGContextSetLineJoin(quartzContext, lineJoinType);
    }
}

@end

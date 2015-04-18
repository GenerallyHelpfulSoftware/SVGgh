//
//  ControlFactory.m
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
//  Created by Glenn Howes on 3/25/12.


#import "GHControlFactory.h"
#import "math.h"
#import "SVGRenderer.h"
#import "GHButton.h"
#import "SVGUtilities.h"
#import "SVGDocumentView.h"


const CGFloat kStandardDarkeningOffset = 0.2;
const CGFloat kPressedButtonDarkeningOffset = 0.25;

NSUInteger gDefaultScheme = kColorSchemeNone;
UIColor* gDefaultButtonColor = nil;

UIColor* gDefaultTextColor = nil;
UIColor* gDefaultPressedTextColor = nil;
UIColor* gDefaultSelectedTextColor = nil;

@implementation GHControlFactory
+(ColorScheme) defaultScheme
{
    return gDefaultScheme;
}


+(NSURL*) locateArtworkForObject:(id<NSObject>)anObject atSubpath:(NSString*)theArtworkPath
{
    NSBundle* myBundle = [NSBundle bundleForClass:[anObject class]];
    NSURL*  result = [myBundle URLForResource:theArtworkPath withExtension:@"svg"];
    if(result == nil)
    {
        myBundle = [NSBundle mainBundle];
        result = [myBundle URLForResource:theArtworkPath withExtension:@"svg"];
    }
    return result;
}

+(BOOL)isValidColorScheme:(ColorScheme)scheme
{
    BOOL result = (scheme <= kLastColorScheme);
    NSAssert(result, @"GHControlFactory: out of range color scheme %lu", (unsigned long)scheme);
    return result;
}


+(void) setDefaultTextColor:(UIColor*)defaultTextColor
{
    gDefaultTextColor = defaultTextColor;
}
+(void) setDefaultPressedTextColor:(UIColor*)defaultPressedTextColor
{
    gDefaultPressedTextColor = defaultPressedTextColor;
}

+(UIColor*)textColor
{
    return gDefaultTextColor;
}

+(UIColor*)pressedTextColor
{
    return gDefaultPressedTextColor;
}


+(void) setDefaultButtonTint:(UIColor*)buttonTint
{
    gDefaultButtonColor = buttonTint;
}

+(UIColor*)buttonTint
{
    UIColor* result = gDefaultButtonColor;
    if(result == nil)
    {
        result = gDefaultButtonColor = [[UIColor alloc] initWithHue:0.611 saturation:0.45 brightness:0.92 alpha:1.0];

    }
    return result;
}

+(UIColor*) newColor:(UIColor*)originalColor withBrightnessDelta:(CGFloat)brightnessDelta
{
    UIColor* result = originalColor;
    CGFloat     hue, saturation, brightness, alpha;
    CGFloat     white;
    if([originalColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha])
    {
        brightness = fmaxf(0, brightness-brightnessDelta);
        result = [[UIColor alloc] initWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
    else if([originalColor getWhite:&white alpha:&alpha])
    {
        white = fmaxf(0, white-brightnessDelta);
        result = [[UIColor alloc] initWithWhite:white alpha:alpha];
    }
    
    return result;
}

+(void) setDefaultScheme:(ColorScheme)defaultScheme
{
    gDefaultScheme = defaultScheme;
}

+(BOOL) preferRadialGradientForScheme:(ColorScheme)scheme
{
    BOOL result = NO;
    switch(scheme)
    {
        case kColorSchemeiOS:
        case kColorSchemeMachine:
        {
            result = YES;
        }
        break;
        default:
        {
            result = NO;
        }
        break;
    }
    return result;
}

+(UIColor*) newLightBackgroundColorForScheme:(ColorScheme)scheme
{
    UIColor* result = nil;
    switch(scheme)
    {
        case kColorSchemeKeyboard:
        case kColorSchemeMachine:
        {
            result = [[UIColor alloc] initWithWhite:0.99 alpha:1.0];
        }
        break;
        case kColorSchemeEmpty:
        case kColorSchemeClear:
        {
            result = [[UIColor alloc] initWithWhite:0.99 alpha:0.25];
        }
        break;
        case kColorSchemeHomeTheatre:
        {
            result = [[UIColor alloc] initWithHue:0.122 saturation:0.78 brightness:0.99 alpha:1.0];
        }
        break;
        case kColorSchemeiOS:
        {
            result = [GHControlFactory buttonTint];
        }
        break;
        case kColorSchemeFlatAndBoxy:
        {
            result = [GHControlFactory buttonTint];
        }
        break;
        default:
        {
            (void)[GHControlFactory isValidColorScheme:scheme];
        }
        break;
    }

    return result;
}

+(UIColor*) newPressedColorForColor:(UIColor*)originalColor forScheme:(ColorScheme)scheme
{
    UIColor* result = [GHControlFactory newColor:originalColor withBrightnessDelta:kPressedButtonDarkeningOffset];
    return result;
}


+(CGPathRef) newRoundRectPathForRect:(CGRect)aRect withRadius:(CGFloat) radius
{
    CGMutablePathRef mutableResult = CGPathCreateMutable();
    CGPathMoveToPoint(mutableResult, NULL, aRect.origin.x+radius+1, aRect.origin.y);
    
    CGPathAddArc(mutableResult, NULL,
                 aRect.origin.x+aRect.size.width-radius, aRect.origin.y+radius, radius, M_PI+M_PI_2, 2.0*M_PI,
                 false);
    
    CGPathAddArc(mutableResult, NULL,
                 aRect.origin.x+aRect.size.width-radius, aRect.origin.y+aRect.size.height-radius, radius, 0, M_PI_2,
                 false);
    
    CGPathAddArc(mutableResult, NULL,
                 aRect.origin.x+radius, aRect.origin.y+aRect.size.height-radius, radius, M_PI_2, M_PI,
                 false);
    
    CGPathAddArc(mutableResult, NULL,
                 aRect.origin.x+radius, aRect.origin.y+radius, radius, M_PI, M_PI+M_PI_2,
                 false);
    
    CGPathCloseSubpath(mutableResult);
    
    return mutableResult;
}


+(CGGradientRef) newButtonBackgroundGradientForScheme:(ColorScheme)scheme withBrighnessOffset:(CGFloat)brightnessOffset
{
    CGGradientRef   result = 0;
    (void)[GHControlFactory isValidColorScheme:scheme];
    switch(scheme)
    {
        case kColorSchemeKeyboard:
        case kColorSchemeMachine:
        case kColorSchemeiOS:
        {
            UIColor* lightColor = [GHControlFactory newLightBackgroundColorForScheme:scheme];
            
            if(brightnessOffset != 0)
            {
                lightColor = [GHControlFactory newColor:lightColor
                                  withBrightnessDelta:brightnessOffset];
            }
            
            UIColor* middleColor = [GHControlFactory newColor:lightColor
                                        withBrightnessDelta:.03];
            UIColor* darkColor = [GHControlFactory newColor:middleColor
                                      withBrightnessDelta:.03];
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
            
            CFArrayCallBacks callBacks = kCFTypeArrayCallBacks;
            CFMutableArrayRef	colors = CFArrayCreateMutable(kCFAllocatorDefault,6, &callBacks);
            
            CFArrayAppendValue(colors, lightColor.CGColor);
            CFArrayAppendValue(colors, middleColor.CGColor);
            CFArrayAppendValue(colors, darkColor.CGColor);
            
            CGFloat locations[] = {0.0, 0.7, 1.0};
            
            result = CGGradientCreateWithColors(colorSpace, colors, locations);
            CFRelease(colors);
            CGColorSpaceRelease(colorSpace);
        }
        break;
        case kColorSchemeFlatAndBoxy:
        {
        }
        break;
        default:
        {
            UIColor* lightColor = [GHControlFactory newLightBackgroundColorForScheme:scheme];
            
            if(brightnessOffset != 0)
            {
                lightColor = [GHControlFactory newColor:lightColor
                                   withBrightnessDelta:brightnessOffset];
            }
            
            UIColor* middleColor = [GHControlFactory newColor:lightColor
                                        withBrightnessDelta:kStandardDarkeningOffset/2];
            UIColor* darkColor = [GHControlFactory newColor:middleColor
                                      withBrightnessDelta:kStandardDarkeningOffset/2];
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
            
            CFArrayCallBacks callBacks = kCFTypeArrayCallBacks;
            CFMutableArrayRef	colors = CFArrayCreateMutable(kCFAllocatorDefault,6, &callBacks);
            
            CFArrayAppendValue(colors, lightColor.CGColor);
            CFArrayAppendValue(colors, lightColor.CGColor);
            CFArrayAppendValue(colors, middleColor.CGColor);
            CFArrayAppendValue(colors, darkColor.CGColor);          
            CFArrayAppendValue(colors, darkColor.CGColor);
            
            CGFloat locations[] = {0.0, 0.25, 0.5, 0.75, 1.0};
            
            result = CGGradientCreateWithColors(colorSpace, colors, locations);
            CFRelease(colors);
            CGColorSpaceRelease(colorSpace);
        }
        break;
        
    }

    return result;
}

+(CGGradientRef) newButtonBackgroundGradientForScheme:(ColorScheme)aScheme
{
    CGGradientRef   result = nil;
    switch(aScheme)
    {
        default:
            result = [GHControlFactory newButtonBackgroundGradientForScheme:aScheme
                                                      withBrighnessOffset:0.0];
        break;
    }
    return result;
}

+(CGGradientRef) newButtonBackgroundGradientPressedForScheme:(ColorScheme)scheme
{
    CGGradientRef   result = nil;
    switch(scheme)
    {
        case kColorSchemeiOS:
        case kColorSchemeMachine:
        {
            result = [self newButtonBackgroundGradientForScheme:scheme];// use the same one
        }
        break;
        default:
        {
            result = [GHControlFactory newButtonBackgroundGradientForScheme:scheme withBrighnessOffset:kPressedButtonDarkeningOffset];
        }
        break;
    }
    return result;
}

+(CGGradientRef) newButtonBackgroundGradientSelectedForScheme:(ColorScheme)scheme
{
    CGGradientRef   result = nil;
    switch(scheme)
    {
        case kColorSchemeKeyboard:
        {
            UIColor* lightColor = UIColorFromSVGColorString(@"#f6cd1d");
            
            UIColor* middleColor = [GHControlFactory newColor:lightColor
                                        withBrightnessDelta:.03];
            UIColor* darkColor = [GHControlFactory newColor:middleColor
                                      withBrightnessDelta:.03];
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
            
            CFArrayCallBacks callBacks = kCFTypeArrayCallBacks;
            CFMutableArrayRef	colors = CFArrayCreateMutable(kCFAllocatorDefault,6, &callBacks);
            
            CFArrayAppendValue(colors, lightColor.CGColor);
            CFArrayAppendValue(colors, middleColor.CGColor);
            CFArrayAppendValue(colors, darkColor.CGColor);
            
            CGFloat locations[] = {0.0, 0.7, 1.0};
            
            result = CGGradientCreateWithColors(colorSpace, colors, locations);
            CFRelease(colors);
            CGColorSpaceRelease(colorSpace);
        }
        break;
        case kColorSchemeFlatAndBoxy:
        {
        }
        break;
        default:
        {
            result = [GHControlFactory newButtonBackgroundGradientPressedForScheme:scheme];
        }
        break;
    }
    return result;
}

+(UIColor*) newTextColorPressedForScheme:(ColorScheme)scheme
{
    UIColor* result = [GHControlFactory pressedTextColor];
    if(result == nil)
    {
        switch(scheme)
        {
            case kColorSchemeiOS:
            case kColorSchemeMachine:
            {
                result = [self newTextColorForScheme:scheme];
            }
            break;
            case kColorSchemeEmpty:
            {
                result = [GHControlFactory buttonTint];
                result = [GHControlFactory newColor:result withBrightnessDelta:0.5];
            }
            break;
            case kColorSchemeClear:
            {
                result = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
            }
            break;
            default:
            {
                result = [UIColor whiteColor];
                (void)[GHControlFactory isValidColorScheme:scheme];
            }
            break;
        }
    }

    return result;
}

+(UIColor*) newTextColorForScheme:(ColorScheme)scheme
{
    UIColor* result = [GHControlFactory textColor];
    if(result == nil)
    {
        switch(scheme)
        {
            case kColorSchemeiOS:
            case kColorSchemeMachine:
            {
                result = [[UIColor alloc] initWithWhite:0.35 alpha:1.0];
                (void)[GHControlFactory isValidColorScheme:scheme];
            }
            break;
            case kColorSchemeEmpty:
            {
                result = [GHControlFactory buttonTint];
            }
            break;
            case kColorSchemeClear:
            {
                result = [[UIColor blackColor] colorWithAlphaComponent:0.50];
            }
            break;
            default:
            {
                result = [UIColor blackColor];
                (void)[GHControlFactory isValidColorScheme:scheme];
            }
            break;
        }
    }
    return result;
}

+(UIColor*) newTextShadowColorForScheme:(ColorScheme)scheme
{
    UIColor* result = nil;
    switch(scheme)
    {
        default:
        {
            result = [GHControlFactory newLightBackgroundColorForScheme:scheme]; 
            (void)[GHControlFactory isValidColorScheme:scheme];
        }
        break;
    }
    return result;
}
+(UIColor*) newRingColorForScheme:(ColorScheme)scheme
{
    UIColor* result = nil;
    switch(scheme)
    {
        case kColorSchemeMachine:
        {
            result = [UIColor cyanColor];
        }
        break;
        case kColorSchemeiOS:
        {
            result = [UIColor clearColor];
            (void)[GHControlFactory isValidColorScheme:scheme];
        }
            break;
        case kColorSchemeClear:
        {
            result = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        }
        break;
        default:
        {
            result = [UIColor blackColor];
            (void)[GHControlFactory isValidColorScheme:scheme];
        }
        break;
    }
    return result;
}

+(GHButton*) newButtonForScheme:(ColorScheme)scheme
{
    GHButton*  result = [[GHButton alloc] initWithFrame:CGRectZero];
    switch(scheme)
    {
        default:
        {
            [result setSchemeNumber:scheme];
        }
        break;
    }
    return result;
} 

@end




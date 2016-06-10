//
//  GHControl.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2011-2015 Glenn R. Howes

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

#import "GHControl.h"
#import "GHControlFactory.h"


const CGFloat kButtonTitleFontSize = 16.0;
const CGFloat kRingThickness = 2.0;
const CGFloat kRoundButtonRadius = 8.0;
const CGFloat kShadowInset = 3.0;
@interface GHControl ()
@property(nonatomic, strong) UIColor* explicitBaseColor;
@property(nonatomic, strong) UIColor* explicitPressedColor;
@property(nonatomic, strong) UIColor* explicitSelectedColor;
@property(nonatomic, strong) UIColor* explicitDisabledColor;


@property(nonatomic, strong) UIColor* defaultBaseColor;
@property(nonatomic, strong) UIColor* defaultPressedColor;
@property(nonatomic, strong) UIColor* defaultSelectedColor;
@property(nonatomic, strong) UIColor* defaultDisabledColor;

@end


@implementation GHControl
;

+(void)makeSureLoaded
{
}


-(instancetype) initWithFrame:(CGRect)frame
{
    if(nil != (self = [super initWithFrame:frame]))
    {
        if([GHControlFactory defaultScheme] != kColorSchemeNone)
        {
            [self setupForScheme:[GHControlFactory defaultScheme]];
        }
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if(nil != (self = [super initWithCoder:aDecoder]))
    {
        if([GHControlFactory defaultScheme] != kColorSchemeNone)
        {
            [self setupForScheme:[GHControlFactory defaultScheme]];
        }
    }
    return self;
}

-(void) setSchemeNumber:(NSInteger)schemeNumber
{
    if(kColorSchemeiOSVersionAppropriate == schemeNumber)
    {
#if TARGET_OS_TV
        schemeNumber = kColorSchemeTVOS;
#else
        NSString* systemVersion = [UIDevice currentDevice].systemVersion;
        if(systemVersion.doubleValue >= 7)
        {
            schemeNumber = kColorSchemeEmpty;
        }
        else
        {
            schemeNumber = kColorSchemeiOS;
        }
#endif
    }
    self.scheme = schemeNumber;
    [self setupForScheme:self.scheme];
}

-(void) setArtInsetFraction:(CGFloat)artInsetFraction
{
    NSAssert(artInsetFraction < 0.5, @"artInsetFraction should be between 0 and 0.5, preferabley under 0.25");
    
    _artInsetFraction = artInsetFraction;
}

-(void)setupForScheme:(NSUInteger)aScheme
{
    (void)[GHControlFactory isValidColorScheme:aScheme];
    self.scheme = aScheme;
    CGGradientRef faceGradient = [GHControlFactory newButtonBackgroundGradientForScheme:aScheme];
    self.faceGradient = faceGradient;
    CGGradientRelease(faceGradient);
    
    CGGradientRef pressed = [GHControlFactory newButtonBackgroundGradientPressedForScheme:aScheme];
    CGGradientRef selected = [GHControlFactory newButtonBackgroundGradientSelectedForScheme:aScheme];
    self.faceGradientSelected = selected;
    self.faceGradientPressed = pressed;
    CGGradientRelease(pressed);
    CGGradientRelease(selected);
    
    self.defaultBaseColor = [GHControlFactory newTextColorForScheme:aScheme];
    self.defaultPressedColor = [GHControlFactory newTextColorPressedForScheme:aScheme];
    self.defaultDisabledColor = [UIColor lightGrayColor];
    self.ringColor = [GHControlFactory newRingColorForScheme:aScheme];
    self.textShadowColor = [GHControlFactory newLightBackgroundColorForScheme:aScheme];
    self.useRadialGradient = [GHControlFactory preferRadialGradientForScheme:aScheme];
    self.textFontSize = kButtonTitleFontSize;
    self.useBoldText = NO;
    self.drawsChrome = YES;
    self.drawsBackground = YES;
    switch (aScheme)
    {
        case kColorSchemeKeyboard:
        {
            self.useBoldText = YES;
            self.showShadow = YES;
        }
        break;
        case kColorSchemeEmpty:
        {
            self.drawsChrome = NO;
            self.drawsBackground = NO;
        }
        break;
        case kColorSchemeTVOS:
        {
            self.drawsBackground = NO;
            
            if([GHControlFactory textColor] == nil)
            {
                self.defaultBaseColor = self.tintColor;
            }
            if([GHControlFactory pressedTextColor] == nil)
            {
                //self.
            }
            
            self.defaultSelectedColor = self.defaultPressedColor;
        }
        break;
        case kColorSchemeFlatAndBoxy:
        {
            self.drawsBackground = YES;
            self.drawsChrome = NO;
        }
        default:
        break;
    }
}

-(void) setTextColor:(UIColor *)textColor
{
    self.explicitBaseColor = textColor;
}

-(UIColor*) textColor
{
    UIColor* result = self.explicitBaseColor;
    if(result == nil)
    {
        result = self.defaultBaseColor;
    }
    return result;
}

-(void) setTextColorPressed:(UIColor *)textColorPressed
{
    self.explicitPressedColor = textColorPressed;
}

-(UIColor*) textColorPressed
{
    UIColor* result = self.explicitPressedColor;
    if(result == nil)
    {
        result = self.defaultPressedColor;
    }
    return result;
}

-(void) setTextColorSelected:(UIColor *)textColorSelected
{
    self.explicitSelectedColor = textColorSelected;
}

-(void) setTextColorDisabled:(UIColor *)textColorDisabled
{
    self.explicitDisabledColor  = textColorDisabled;
}

-(UIColor*) textColorDisabled
{
    UIColor* result = self.explicitDisabledColor;
    if(result == nil)
    {
        result = self.defaultDisabledColor;
    }
    if(result == nil)
    {
        result = [UIColor lightGrayColor];
    }
    return result;
}

-(UIColor*) textColorSelected
{
    UIColor* result = self.explicitSelectedColor;
    if(result == nil)
    {
        result = self.defaultSelectedColor;
    }
    return result;

}

-(void) setEnabled:(BOOL)enabled
{
    BOOL isChange = (enabled != self.enabled);
    [super setEnabled:enabled];
    if(isChange)
    {
        [self setNeedsDisplay];
    }
}

-(NSInteger)schemeNumber
{
    return  self.scheme;
}

-(void) setFaceGradient:(CGGradientRef)faceGradient
{
    CGGradientRef oldFaceGradient = _faceGradient;
    CGGradientRetain(faceGradient);
    _faceGradient = faceGradient;
    CGGradientRelease(oldFaceGradient);
}

-(void) setFaceGradientPressed:(CGGradientRef)faceGradientPressed
{
    CGGradientRef oldFaceGradient = _faceGradientPressed;
    CGGradientRetain(faceGradientPressed);
    _faceGradientPressed = faceGradientPressed;
    CGGradientRelease(oldFaceGradient);
}

-(void)setFaceGradientSelected:(CGGradientRef)faceGradientSelected
{
    CGGradientRef oldFaceGradient = _faceGradientSelected;
    CGGradientRetain(faceGradientSelected);
    _faceGradientSelected = faceGradientSelected;
    CGGradientRelease(oldFaceGradient);
}


-(void) dealloc
{
    CGGradientRelease(_faceGradient);
    CGGradientRelease(_faceGradientPressed);
    CGGradientRelease(_faceGradientSelected);
}

@end

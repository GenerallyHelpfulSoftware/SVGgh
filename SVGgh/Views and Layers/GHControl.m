//
//  GHControl.m
//  SVGgh
//
//  Created by Glenn Howes on 2015-03-26.
//  Copyright (c) 2015 Generally Helpful Software. All rights reserved.
//

#import "GHControl.h"


const CGFloat kButtonTitleFontSize = 16.0;

@interface GHControl ()


@end


@implementation GHControl
;

+(void)makeSureLoaded
{
}


-(id) initWithFrame:(CGRect)frame
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

-(id) initWithCoder:(NSCoder *)aDecoder
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
        NSString* systemVersion = [UIDevice currentDevice].systemVersion;
        if(systemVersion.doubleValue >= 7)
        {
            schemeNumber = kColorSchemeEmpty;
        }
        else
        {
            schemeNumber = kColorSchemeiOS;
        }
    }
    self.scheme = schemeNumber;
    [self setupForScheme:self.scheme];
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
    
    self.textColor = [GHControlFactory newTextColorForScheme:aScheme];
    self.textColorPressed = [GHControlFactory newTextColorPressedForScheme:aScheme];
    self.ringColor = [GHControlFactory newRingColorForScheme:aScheme];
    self.textShadowColor = [GHControlFactory newLightBackgroundColorForScheme:aScheme];
    self.backgroundColor = [UIColor clearColor];
    self.useRadialGradient = [GHControlFactory preferRadialGradientForScheme:aScheme];
    self.textFontSize = kButtonTitleFontSize;
    self.useBoldText = NO;
    self.drawsChrome = YES;
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
        }
        default:
            break;
    }
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

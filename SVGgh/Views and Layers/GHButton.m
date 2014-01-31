//
//  GHButton.m
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

//  Created by Glenn Howes on 1/26/14.


#import "GHButton.h"
#import "GHControlFactory.h"
#import "SVGRenderer.h"

const CGFloat kButtonTitleFontSize = 16.0;
const CGFloat kRingThickness = 2.0;
const CGFloat kRoundButtonRadius = 8.0;
const CGFloat kButtonShadowDistance = 2.0;

@interface KeyboardPressedPopup : UIView
@property(nonatomic, assign) GHButton* parent;
@property(nonatomic, strong) NSString* artworkPath;
@property(nonatomic, assign) UILabel*      textLabel;
@end

@interface GHButton ()
{
@private
    UIColor*            textColor;
    UIColor*            textColorPressed;
    UIColor*            ringColor;
    NSString*           title;
    UILabel*            textLabel;
    CGFloat             textFontSize;
    BOOL                useBoldText;
    BOOL                showShadow;
}
@property(nonatomic, strong) UILabel*      textLabel;
@property(nonatomic, strong) KeyboardPressedPopup*        pressedView;
-(void) setupForScheme:(NSUInteger)aScheme;
@end


@implementation GHButton
@synthesize faceGradient=_faceGradient;
@synthesize faceGradientPressed=_faceGradientPressed, faceGradientSelected=_faceGradientSelected,
textColor, textColorPressed, ringColor, textLabel, textShadowColor,
useRadialGradient=_useRadialGradient,scheme=_scheme;

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

-(NSInteger)schemeNumber
{
    return  self.scheme;
}

-(void) setTextColor:(UIColor *)newTextColor
{
    [self syncTextColor];
    textColor=newTextColor;
    if(self.artworkPath.length)
    {
        [self setNeedsDisplay];
    }
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
    textFontSize = kButtonTitleFontSize;
    useBoldText = NO;
    self.drawsChrome = YES;
    switch (aScheme)
    {
        case kColorSchemeKeyboard:
        {
            useBoldText = YES;
            showShadow = YES;
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

-(NSString*)title
{
    return self.textLabel.text;
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

-(void) syncTextColor
{
    BOOL    inNormalMode = !(self.isSelected || self.isHighlighted);
    UIColor*        textColorToUse = inNormalMode?self.textColor:self.textColorPressed;
    self.textLabel.textColor = textColorToUse;
    self.textLabel.shadowOffset = CGSizeMake(0, 1);
    self.textLabel.shadowColor = textShadowColor;
}

-(void) setNeedsDisplay
{
    [self syncTextColor];
    [super setNeedsDisplay];
}

-(void) setSelected:(BOOL)selected
{
    BOOL isChange = selected != self.isSelected;
    [super setSelected:selected];
    if(isChange)
    {
        [self setNeedsDisplay];
    }
    if([self.artworkView respondsToSelector:@selector(setSelected:)])
    {
        [(UIControl*)self.artworkView setSelected:selected];
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

-(void) setHighlighted:(BOOL)highlighted
{
    BOOL isChange = highlighted != self.isHighlighted;
    [super setHighlighted:highlighted];
    if([self.artworkView respondsToSelector:@selector(setHighlighted:)])
    {
        [(UIControl*)self.artworkView setHighlighted:highlighted];
    }
    if(isChange)
    {
        if(self.pressedView != nil)
        { // remove a flyout
            [self.pressedView removeFromSuperview];
            self.pressedView = nil;
            [self setNeedsDisplay];
        }
        else if((self.scheme == kColorSchemeKeyboard && self.artworkPath) || self.pressedArtworkPath)
        {// fly out a pressed keyboard view so the user can see what they are pressing
            CGRect myFrame = self.frame;
            
            CGRect pressedFrame;
            if(self.pressedArtworkPath.length)
            {
                pressedFrame = CGRectMake(myFrame.origin.x-myFrame.size.width/2.0, myFrame.origin.y-myFrame.size.height*2, myFrame.size.width*3.0, myFrame.size.height*3);
            }
            else
            {
                pressedFrame = CGRectMake(myFrame.origin.x, myFrame.origin.y-myFrame.size.height*1.5, myFrame.size.width, myFrame.size.height*2.5);
            }
            if(pressedFrame.origin.x < 0)
            {
                pressedFrame.origin.x = 0;
            }
            else if(pressedFrame.origin.x+pressedFrame.size.width > self.superview.bounds.size.width)
            {
                pressedFrame.origin.x = self.superview.bounds.size.width-pressedFrame.size.width;
            }
            
            KeyboardPressedPopup* pressedView = [[KeyboardPressedPopup alloc] initWithFrame:pressedFrame];
            
            pressedView.parent = self;
            pressedView.artworkPath = self.pressedArtworkPath.length?self.pressedArtworkPath:self.artworkPath;
            self.pressedView = pressedView;
            [self.superview addSubview:pressedView];
        }
        else
        {
            [self setNeedsDisplay];
        }
    }
}

-(void) setTitle:(NSString *)newTitle
{
    NSString* localizedTitle= [[NSBundle mainBundle] localizedStringForKey:newTitle value:@"" table:nil];
    if(self.textLabel == nil)
    {// we use a regular UILabel to handle text (much simpler that way)
        UILabel* theTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel = theTextLabel;
        self.textLabel.font = useBoldText?[UIFont boldSystemFontOfSize:textFontSize]:[UIFont systemFontOfSize:textFontSize];
        self.textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:theTextLabel];
        [self syncTextColor];
    }
    self.textLabel.text = localizedTitle;
    [self setNeedsLayout];
}

-(void)drawBackgroundIntoContext:(CGContextRef)quartzContext
{
    CGContextSaveGState(quartzContext);
    BOOL drawRing = YES;
    BOOL    inNormalMode = !(self.isSelected || self.isHighlighted);
    CGGradientRef   gradientToUse = 0;
    if(self.isSelected)
    {
        gradientToUse = self.faceGradientSelected;
    }
    else if(self.isHighlighted)
    {
        gradientToUse = self.faceGradientPressed;
    }
    else
    {
        gradientToUse = self.faceGradient;
    }
    
    NSAssert((gradientToUse != 0), @"RoundButton: Not setup properly");
    
    // draw subtly gradiented interior
    CGRect interiorRect = self.useRadialGradient?self.bounds:CGRectInset(self.bounds, kRingThickness, kRingThickness);
    
    if(showShadow)
    {
        drawRing = NO;
    }
    
    
    CGPathRef   boundingPath = [GHControlFactory newRoundRectPathForRect:interiorRect withRadius:kRoundButtonRadius];
    
    CGContextSaveGState(quartzContext);
    CGContextAddPath(quartzContext, boundingPath);
    CGContextClip(quartzContext);
    
    CGPoint topPoint = self.bounds.origin;
    CGPoint bottomPoint = CGPointMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height);
    if(self.useRadialGradient)
    {
        CGContextSaveGState(quartzContext);
        CGContextTranslateCTM(quartzContext, interiorRect.origin.x, interiorRect.origin.y);
        CGContextScaleCTM(quartzContext, interiorRect.size.width, interiorRect.size.height);
        CGContextScaleCTM(quartzContext, 1.0, .5);
        
        CGFloat startRadius = .2;
        CGFloat endRadius = 1.0;
        CGPoint startPoint = CGPointMake(.1, .2);
        CGContextDrawRadialGradient(quartzContext,gradientToUse,
                                    startPoint, startRadius,
                                    startPoint, endRadius, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextRestoreGState(quartzContext);
        
        CGRect ringRect = CGRectInset(interiorRect, 3.0, 3.0);
        CGPathRef ringPath = [GHControlFactory newRoundRectPathForRect:ringRect withRadius:kRoundButtonRadius-2];
        CGContextSetLineWidth(quartzContext, 0.5);
        if(inNormalMode)
        {
            CGContextSetStrokeColorWithColor(quartzContext, [[UIColor darkGrayColor] colorWithAlphaComponent:0.5].CGColor);
        }
        else
        {
            CGContextSetStrokeColorWithColor(quartzContext, self.ringColor.CGColor);
        }
        CGContextAddPath(quartzContext, ringPath);
        CGContextStrokePath(quartzContext);
        CGPathRelease(ringPath);
        drawRing = NO;
    }
    else
    {
        CGContextDrawLinearGradient(quartzContext,gradientToUse, topPoint, bottomPoint, 0);
    }
    CGContextRestoreGState(quartzContext);
    CGPathRelease(boundingPath);
    
    // draw ring
    if(drawRing)
    {
        CGRect ringRect = CGRectInset(self.bounds, kRingThickness, kRingThickness);
        
        boundingPath = [GHControlFactory newRoundRectPathForRect:ringRect  withRadius:kRoundButtonRadius];
        CGContextSetLineWidth(quartzContext, 0.5);
        CGContextSetStrokeColorWithColor(quartzContext, self.ringColor.CGColor);
        
        CGContextAddPath(quartzContext, boundingPath);
        CGContextStrokePath(quartzContext);
        CGPathRelease(boundingPath);
    }
    
    CGContextRestoreGState(quartzContext);
}

-(void) drawArtWithRenderer:(SVGRenderer*)renderer  intoContext:(CGContextRef)quartzContext
{
    if(renderer != nil)
    {
        CGContextSaveGState(quartzContext);
        
        BOOL    inNormalMode = !(self.isSelected || self.isHighlighted);
        
        UIColor* currentColor = nil;
        
        if(inNormalMode)
        {
            currentColor = self.textColor;
        }
        else
        {
            currentColor = self.textColorPressed;
        }
        
        if(!self.enabled)
        {
            currentColor = [UIColor lightGrayColor];
        }
        
        renderer.currentColor = currentColor;
        
        CGRect interiorRect = (self.useRadialGradient || !self.drawsChrome)?self.bounds:CGRectInset(self.bounds, kRingThickness, kRingThickness);
        if(self.drawsChrome)
        {// make space for the chrome
            interiorRect = CGRectInset(interiorRect, 5, 5);
        }
        CGContextClipToRect(quartzContext, interiorRect);
        
        // now figure out where to put my artwork and at what scale factor
        CGRect viewRect = renderer.viewRect;
        CGFloat interiorAspectRatio = interiorRect.size.width/interiorRect.size.height;
        CGFloat rendererAspectRatio = viewRect.size.width/viewRect.size.height;
        CGFloat scaling;
        if(interiorAspectRatio >= rendererAspectRatio)
        {
            scaling = interiorRect.size.height/viewRect.size.height;
        }
        else
        {
            scaling = interiorRect.size.width/viewRect.size.width;
        }
        
        CGFloat scaledWidth = viewRect.size.width*scaling;
        CGFloat scaleHeight = viewRect.size.height*scaling;
        
        // setup the drawing environment for the renderer
        CGContextTranslateCTM(quartzContext, interiorRect.origin.x+(interiorRect.size.width-scaledWidth)/2.0, interiorRect.origin.y+(interiorRect.size.height-scaleHeight)/2.0);
        CGContextScaleCTM(quartzContext, scaling, scaling);
        
        // tell the renderer to draw into my context
        [renderer renderIntoContext:quartzContext];
        CGContextRestoreGState(quartzContext);
        
    }
}

-(void)drawArtworkAtPath:(NSString*)theArtworkPath intoContext:(CGContextRef)quartzContext
{
    NSURL*  myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:theArtworkPath];
    
    if(myArtwork != nil)
    {// draw my SVG
        SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
        [self drawArtWithRenderer:renderer intoContext:quartzContext];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef quartzContext = UIGraphicsGetCurrentContext();
    if(self.drawsChrome)
    {
        [self drawBackgroundIntoContext:quartzContext];
    }
    if(self.selected && self.selectedArtworkPath.length)
    {
        [self drawArtworkAtPath:self.selectedArtworkPath intoContext:quartzContext];
    }
    else if(self.artworkPath.length)
    {
        [self drawArtworkAtPath:self.artworkPath intoContext:quartzContext];
    }
}

-(void) setArtworkPath:(NSString *)artworkPath
{
    _artworkPath = artworkPath;
    if(artworkPath.length)
    {
        [self setContentMode:UIViewContentModeRedraw];
    }
}

- (void)layoutSubviews
{
    CGRect myRectInsideRadius = CGRectInset(self.bounds, kRoundButtonRadius, kRoundButtonRadius);
    if(self.textLabel != nil)
    {
        CGRect neededRect = [self.textLabel textRectForBounds:myRectInsideRadius limitedToNumberOfLines:1];
        neededRect.origin = CGPointMake(kRoundButtonRadius+(myRectInsideRadius.size.width-neededRect.size.width)/2,
                                        kRoundButtonRadius+(myRectInsideRadius.size.height-neededRect.size.height)/2);
        self.textLabel.frame = neededRect;
    }
}

-(void) dealloc
{
    CGGradientRelease(_faceGradient);
    CGGradientRelease(_faceGradientPressed);
    CGGradientRelease(_faceGradientSelected);
}
@end

@implementation KeyboardPressedPopup

-(id) initWithFrame:(CGRect)frame
{
    if(nil != (self = [super initWithFrame:frame]))
    {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void) layoutSubviews
{
    if(_textLabel == nil && self.parent.textLabel != nil)
    {
        CGRect parentLabelRect;
        if(self.artworkPath.length)
        {
            parentLabelRect = [self convertRect:self.parent.textLabel.bounds fromView:self.parent.textLabel];
        }
        else
        {
            parentLabelRect = self.parent.textLabel.frame;
        }
        UILabel* theTextLabel = [[UILabel alloc] initWithFrame:parentLabelRect];
        self.textLabel = theTextLabel;
        theTextLabel.font = self.parent.textLabel.font;
        self.textLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:theTextLabel];
        self.textLabel.text = self.parent.textLabel.text;
        
        self.textLabel.textColor = self.parent.textLabel.textColor;
        self.textLabel.shadowOffset = self.parent.textLabel.shadowOffset;
        self.textLabel.shadowColor = self.parent.textLabel.shadowColor;
    }
    [super layoutSubviews];
}

-(void)drawBackgroundIntoContext:(CGContextRef)quartzContext
{
    const CGFloat kShadowInset = 3.0;
    CGContextSaveGState(quartzContext);
    
    CGRect parentRect = [self convertRect:self.parent.bounds fromView:self.parent];
    CGRect myBounds = self.bounds;
    UIColor* lightColor = [GHControlFactory newLightBackgroundColorForScheme:self.parent.scheme];
    
    lightColor = [GHControlFactory newColor:lightColor
                      withBrightnessDelta:.05];
    
    UIColor* middleColor = [GHControlFactory newColor:lightColor
                                withBrightnessDelta:.05];
    UIColor* darkColor = [GHControlFactory newColor:middleColor
                              withBrightnessDelta:.11];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceCMYK();
    
    CFArrayCallBacks callBacks = kCFTypeArrayCallBacks;
    CFMutableArrayRef	colors = CFArrayCreateMutable(kCFAllocatorDefault,6, &callBacks);
    
    CFArrayAppendValue(colors, lightColor.CGColor);
    CFArrayAppendValue(colors, middleColor.CGColor);
    CFArrayAppendValue(colors, middleColor.CGColor);
    CFArrayAppendValue(colors, darkColor.CGColor);
    CFArrayAppendValue(colors, middleColor.CGColor);
    CFArrayAppendValue(colors, middleColor.CGColor);
    CFArrayAppendValue(colors, middleColor.CGColor);
    CFArrayAppendValue(colors, darkColor.CGColor);
    
    CGFloat locations[] = {0.0, -.03, 0.03, 0.05, 0.10, 0.15, 0.85, 1.0};
    // need to put a dark fuzzy line to indicate where the button ends and this flyout tab begins
    // as if the tab was up a little hill from the button
    CGFloat centerFraction = parentRect.origin.y/myBounds.size.height;
    for(int i = 1; i < 6;i++) // figure out where the center line should go (not the center, probably
    {
        locations[i] += centerFraction;
    }
    
    CGGradientRef gradientToUse = CGGradientCreateWithColors(colorSpace, colors, locations);
    CFRelease(colors);
    CGColorSpaceRelease(colorSpace);
    
    NSAssert((gradientToUse != 0), @"KeyboardPressedPopup: Not setup properly");
    
    // draw out a roundish tab like area that projects from the parent button
    
    CGFloat radius = kRoundButtonRadius;
    CGRect boundsToFill = CGRectInset(myBounds, kShadowInset, kShadowInset);
    boundsToFill.size.height+= kShadowInset;
    CGMutablePathRef outlinePath = CGPathCreateMutable();
    CGPathMoveToPoint(outlinePath, NULL,
                      myBounds.size.width/2.0, boundsToFill.origin.y);
    
    
    if((myBounds.size.width - (parentRect.origin.x + parentRect.size.width))< 2*radius)
    {
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+parentRect.size.width-radius, boundsToFill.origin.y+radius, radius, M_PI+M_PI_2, 2*M_PI,
                     false);
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+parentRect.size.width-radius, parentRect.origin.y+parentRect.size.height-radius,
                     radius, 0, M_PI_2,
                     false);
    }
    else
    {
        CGPathAddArc(outlinePath, NULL,
                     boundsToFill.origin.x+boundsToFill.size.width-radius, boundsToFill.origin.y+radius, radius, M_PI+M_PI_2, 2*M_PI,
                     false);
        CGPathAddArc(outlinePath, NULL,
                     boundsToFill.origin.x+boundsToFill.size.width-radius, parentRect.origin.y-radius, radius, 0, M_PI_2,
                     false);
        
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+parentRect.size.width+radius, parentRect.origin.y+radius, radius, M_PI_2+M_PI, M_PI,
                     true);
        
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+parentRect.size.width-radius, parentRect.origin.y+parentRect.size.height-radius,
                     radius, 0, M_PI_2,
                     false);
    }
    
    if(parentRect.origin.x > 2*radius)
    {
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+radius, parentRect.origin.y+parentRect.size.height-radius, radius, M_PI_2, M_PI,
                     false);
        
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x-radius, parentRect.origin.y+radius, radius, 2.0*M_PI, M_PI_2+M_PI,
                     true);
        
        
        CGPathAddArc(outlinePath, NULL,
                     boundsToFill.origin.x+radius, parentRect.origin.y-radius, radius, M_PI_2, M_PI,
                     false);
        
        
        CGPathAddArc(outlinePath, NULL,
                     boundsToFill.origin.x+radius, boundsToFill.origin.y+radius, radius, M_PI, M_PI+M_PI_2,
                     false);
    }
    else
    {
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+radius, parentRect.origin.y+parentRect.size.height-radius, radius, M_PI_2, M_PI,
                     false);
        
        CGPathAddArc(outlinePath, NULL,
                     parentRect.origin.x+radius, boundsToFill.origin.y+radius, radius, M_PI, M_PI+M_PI_2,
                     false);
    }
    
    CGPathCloseSubpath(outlinePath);
    
    CGContextSaveGState(quartzContext);
    CGRect clipRect = myBounds;
    clipRect.size.height = parentRect.origin.y+radius;
    CGContextClipToRect(quartzContext, clipRect);
    CGContextAddPath(quartzContext, outlinePath);
    CGContextSetFillColorWithColor(quartzContext, [UIColor grayColor].CGColor);
    CGContextSetShadowWithColor(quartzContext, CGSizeMake(0, 2), 2, [UIColor grayColor].CGColor);
    CGContextFillPath(quartzContext);
    
    CGContextRestoreGState(quartzContext);
    
    CGContextSaveGState(quartzContext);
    CGContextAddPath(quartzContext, outlinePath);
    CGContextClip(quartzContext);
    
    CGPoint topPoint = myBounds.origin;
    CGPoint bottomPoint = CGPointMake(myBounds.origin.x, myBounds.origin.y+myBounds.size.height);
    if(self.parent.useRadialGradient)
    {
        CGContextSaveGState(quartzContext);
        CGContextTranslateCTM(quartzContext, 0, 0);
        CGContextScaleCTM(quartzContext, myBounds.size.width, myBounds.size.height);
        CGContextScaleCTM(quartzContext, 1.0, .5);
        
        CGFloat startRadius = .2;
        CGFloat endRadius = 1.0;
        CGPoint startPoint = CGPointMake(.1, .2);
        CGContextDrawRadialGradient(quartzContext,gradientToUse,
                                    startPoint, startRadius,
                                    startPoint, endRadius, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextRestoreGState(quartzContext);
        
        CGRect ringRect = CGRectInset(myBounds, 3.0, 3.0);
        CGPathRef ringPath = [GHControlFactory newRoundRectPathForRect:ringRect withRadius:kRoundButtonRadius-2];
        CGContextSetLineWidth(quartzContext, 0.5);
        
        CGContextSetStrokeColorWithColor(quartzContext, self.parent.ringColor.CGColor);
        
        CGContextAddPath(quartzContext, ringPath);
        CGContextStrokePath(quartzContext);
        CGPathRelease(ringPath);
    }
    else
    {
        CGContextDrawLinearGradient(quartzContext,gradientToUse, topPoint, bottomPoint, 0);
    }
    
    CGContextRestoreGState(quartzContext);
    CGPathRelease(outlinePath);
    CGGradientRelease(gradientToUse);
    
    CGContextRestoreGState(quartzContext);
}

-(void)drawArtworkAtPath:(NSString*)theArtworkPath intoContext:(CGContextRef)quartzContext
{
    
    NSURL*  myArtwork = [GHControlFactory locateArtworkForObject:self atSubpath:theArtworkPath];;
    if(myArtwork != nil)
    {
        CGContextSaveGState(quartzContext);
        SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
        
        renderer.currentColor = self.parent.textColor;
        
        CGRect parentRect = [self convertRect:self.parent.bounds fromView:self.parent];
        CGRect contentRect = self.bounds;
        contentRect.size.height = parentRect.origin.y;
        // make room for the chrome
        CGRect interiorRect = self.parent.useRadialGradient?contentRect:CGRectInset(contentRect, kRingThickness, kRingThickness);
        interiorRect = CGRectInset(interiorRect, 5, 5);
        CGContextClipToRect(quartzContext, interiorRect);
        CGRect viewRect = renderer.viewRect;
        CGFloat interiorAspectRatio = interiorRect.size.width/interiorRect.size.height;
        CGFloat rendererAspectRatio = viewRect.size.width/viewRect.size.height;
        CGFloat scaling;
        if(interiorAspectRatio >= rendererAspectRatio)
        {
            scaling = interiorRect.size.height/viewRect.size.height;
        }
        else
        {
            scaling = interiorRect.size.width/viewRect.size.width;
        }
        
        CGFloat scaledWidth = viewRect.size.width*scaling;
        CGFloat scaleHeight = viewRect.size.height*scaling;
        
        CGContextTranslateCTM(quartzContext, interiorRect.origin.x+(interiorRect.size.width-scaledWidth)/2.0, interiorRect.origin.y+(interiorRect.size.height-scaleHeight)/2.0);
        CGContextScaleCTM(quartzContext, scaling, scaling);
        
        [renderer renderIntoContext:quartzContext];
        CGContextRestoreGState(quartzContext);
        
    }
}


-(void)drawRect:(CGRect)rect
{
    CGContextRef quartzContext = UIGraphicsGetCurrentContext();
    
    [self drawBackgroundIntoContext:quartzContext];
    if(self.artworkPath.length)
    {
        [self drawArtworkAtPath:self.artworkPath intoContext:quartzContext];
    }
}

@end
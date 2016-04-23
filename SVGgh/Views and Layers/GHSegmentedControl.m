//
//  GHSegmentedControl.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2015 Glenn R. Howes

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
//  Created by Glenn Howes on 2015-03-26.
//


#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import UIKit;
#else
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#endif

#import "GHSegmentedControl.h"
#import "GHControlFactory.h"
#import "SVGRendererLayer.h"

const CGFloat kContentMargin = 10;


typedef enum GHSegmentType
{
    kSegmentTypeRight,
    kSegmentTypeMiddle,
    kSegmentTypeLeft,
    kSegmentTypeOnly
}GHSegmentType;

@class GHSegmentedControlContentView;

@interface GHSegmentedControl()
@property(nonatomic, strong) UIColor* segmentBackgroundColor;
@property(nonatomic, weak) GHSegmentedControlContentView* contentView;
@property(nonatomic, assign) BOOL beingPressed;
@end


@interface GHSegmentDefinition : NSObject
@property(nonatomic, strong) NSString* title;
@property(nonatomic, strong) NSString* accessibilityLabel;
@property(nonatomic, strong) SVGRenderer* renderer;
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) CGFloat width; // 0.0 means automatic
@property(nonatomic, assign) CGFloat artInsetFraction;

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height;

@end

@interface GHSegmentedControlContentView: UIView
@property(nonatomic, strong)        NSArray* definitions; //GHSegmentDefinition
@property(nonatomic,getter=isMomentary) BOOL momentary;
@property(nonatomic)                NSInteger selectedSegmentIndex;
@property(nonatomic, assign)        NSUInteger trackedSegmentIndex;
@property(nonatomic, weak)          GHSegmentedControl* control;
@property(nonatomic, readonly)      UIColor* selectedColor;

+(UIFont*) titleFontForState:(UIControlState)state;

@end


@class GHSegmentedControlSegmentView;


@interface GHSegmentedControlSegmentView: UIView
@property(nonatomic, assign) enum GHSegmentType segmentType;
@property(nonatomic, strong) GHSegmentDefinition* segmentDefinition;
@property(nonatomic, strong) UIColor* currentColor;
@property(nonatomic, assign) BOOL selected;
@property(nonatomic, assign) BOOL isHighlighted;
@property(nonatomic, weak) GHSegmentedControlContentView* parentContent;

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height;

@end

@interface GHSegmentLayer : CALayer
@property(nonatomic, weak) CALayer* contentLayer;
@property(nonatomic, weak) GHSegmentedControlSegmentView* segmentView;

@end

@interface GHSegmentedControlAccessibilityWrapper : UIAccessibilityElement
@property(nonatomic, strong) GHSegmentDefinition* segmentDefinition;
@property(nonatomic, assign) NSInteger index;

@end


@implementation GHSegmentLayer
-(void) layoutSublayers
{
    GHSegmentedControlSegmentView* segmentView = self.segmentView;
    if(self.contentLayer == nil)
    {
        if(segmentView.segmentDefinition.renderer != nil)
        {
            SVGRendererLayer* contentLayer = [[SVGRendererLayer alloc] init];
            contentLayer.renderer = segmentView.segmentDefinition.renderer;
            contentLayer.contentsGravity = kCAGravityResizeAspect;
            contentLayer.defaultColor = segmentView.currentColor;
            [self addSublayer:contentLayer];
            self.contentLayer = contentLayer;
        }
        else if(self.segmentView.segmentDefinition.title.length)
        {
            CATextLayer* contentLayer = [[CATextLayer alloc] init];
            contentLayer.string = segmentView.segmentDefinition.title;
            contentLayer.truncationMode = kCATruncationEnd;
            UIFont* textFont = [GHSegmentedControlContentView titleFontForState:UIControlStateNormal];
            NSString* fontName = textFont.fontName;
            CFStringRef fontNameCF = (__bridge CFStringRef)(fontName);
            CGFontRef fontCG = CGFontCreateWithFontName(fontNameCF);
            contentLayer.font = fontCG;
            CGFontRelease(fontCG);
            contentLayer.fontSize = textFont.pointSize;
            contentLayer.foregroundColor = segmentView.currentColor?segmentView.currentColor.CGColor:[UIColor blackColor].CGColor;
            contentLayer.contentsGravity = kCAGravityCenter;
            contentLayer.alignmentMode = kCAAlignmentCenter;
            
            [self addSublayer:contentLayer];
            self.contentLayer = contentLayer;
        }
        self.contentLayer.contentsScale = self.contentsScale;
        self.contentLayer.backgroundColor = [UIColor clearColor].CGColor;
        self.contentLayer.opaque = NO;
        
    }
    
    CGFloat inset = 2.0;
    
    if(segmentView.segmentDefinition.artInsetFraction > 0)
    {
        inset = self.bounds.size.height*segmentView.segmentDefinition.artInsetFraction;
    }
    
    CGRect contentFrame = CGRectInset(self.bounds, inset, inset);
    
    if([self.contentLayer isKindOfClass:[CATextLayer class]])
    {
        CATextLayer* contentLayer = (CATextLayer*)self.contentLayer;
        CGFontRef font = (CGFontRef)contentLayer.font;
        CGFloat scalingFactor = contentLayer.fontSize/CGFontGetUnitsPerEm(font);
        CGFloat ascent = CGFontGetAscent(font)*scalingFactor;
        CGFloat descent = -1.0*CGFontGetDescent(font)*scalingFactor;
        CGFloat centerY = self.bounds.size.height/2.0;
        contentFrame = CGRectMake(contentFrame.origin.x, centerY-0.5*ascent, contentFrame.size.width, ascent+descent);
        
    }
    
    self.contentLayer.frame = contentFrame;
}

@end


@implementation GHSegmentedControlSegmentView

+(Class)layerClass
{
    return [GHSegmentLayer class];
}

-(instancetype) initWithFrame:(CGRect)frame
{
    if(nil != (self = [super initWithFrame:frame]))
    {
#if !TARGET_OS_TV
        self.userInteractionEnabled = NO;
#endif
    }
    return self;
}

-(void)drawRect:(CGRect)rect
{
}

-(GHSegmentLayer*) segmentLayer
{
    GHSegmentLayer* result = (GHSegmentLayer*)self.layer;
    result.segmentView = self;
    result.backgroundColor = [UIColor clearColor].CGColor;
    result.opaque = NO;
    return result;
}

-(CALayer*)contentLayer
{
    CALayer* result = self.segmentLayer.contentLayer;
    return result;
}

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height
{
    CGFloat result = [self.segmentDefinition preferredWidthGivenHeight:height];
    return result;
}

-(void) setSegmentType:(enum GHSegmentType)segmentType
{
    if(_segmentType != segmentType)
    {
        _segmentType = segmentType;
        [self.layer setNeedsDisplay];
    }
}

-(void) setCurrentColor:(UIColor*)color
{
    BOOL isChange = (_currentColor == nil || ![_currentColor isEqual:color]);
    
    _currentColor = color;
    if(isChange)
    {
        if([self.contentLayer isKindOfClass:[SVGRendererLayer class]])
        {
            SVGRendererLayer* contentLayer = (SVGRendererLayer*)self.contentLayer;
            contentLayer.defaultColor = color;
        }
        else if([self.contentLayer isKindOfClass:[CATextLayer class]])
        {
            CATextLayer* contentLayer = (CATextLayer*)self.contentLayer;
            contentLayer.foregroundColor = color.CGColor;
            [contentLayer setNeedsDisplay];
        }
        [self setNeedsDisplay];
    }
}


-(CGPathRef) newRoundRectPathForRect:(CGRect)aRect withRadius:(CGFloat) radius
{
    CGMutablePathRef mutableResult = CGPathCreateMutable();
    
    switch (self.segmentType) {
        case kSegmentTypeRight:
        {
            CGPathMoveToPoint(mutableResult, NULL, 0, aRect.origin.y);
            
            CGPathAddArc(mutableResult, NULL,
                         aRect.origin.x+aRect.size.width-radius, aRect.origin.y+radius, radius, M_PI+M_PI_2, 2.0*M_PI,
                         false);
            
            CGPathAddArc(mutableResult, NULL,
                         aRect.origin.x+aRect.size.width-radius, aRect.origin.y+aRect.size.height-radius, radius, 0, M_PI_2,
                         false);
            CGPathAddLineToPoint(mutableResult, NULL, 0, aRect.origin.y+aRect.size.height);
            CGPathCloseSubpath(mutableResult);
            
        }
        break;
        case kSegmentTypeMiddle:
        {
            CGRect middleRect = CGRectMake(0, aRect.origin.y, self.bounds.size.width, aRect.size.height);
            CGPathAddRect(mutableResult, NULL, middleRect);
        }
        break;
            
        case kSegmentTypeLeft:
        {
            CGPathMoveToPoint(mutableResult, NULL, aRect.origin.x+radius+1, aRect.origin.y);
            CGPathAddLineToPoint(mutableResult, NULL, self.bounds.size.width, aRect.origin.y);
            CGPathAddLineToPoint(mutableResult, NULL, self.bounds.size.width, aRect.origin.y+aRect.size.height);
            
            CGPathAddArc(mutableResult, NULL,
                         aRect.origin.x+radius, aRect.origin.y+aRect.size.height-radius, radius, M_PI_2, M_PI,
                         false);
            
            CGPathAddArc(mutableResult, NULL,
                         aRect.origin.x+radius, aRect.origin.y+radius, radius, M_PI, M_PI+M_PI_2,
                         false);
            CGPathCloseSubpath(mutableResult);
        }
        break;
        case kSegmentTypeOnly:
        {
            CGPathRef roundRect =  [GHControlFactory newRoundRectPathForRect:aRect withRadius:radius];
            CGPathAddPath(mutableResult, NULL, roundRect);
            CGPathRelease(roundRect);
        }
        break;
            
    }
    
    return mutableResult;
}

-(CGPathRef) newOutlinePathWhileUsingRadialGradient:(BOOL)useRadialGradient
{
    CGRect interiorRect = useRadialGradient?self.bounds:CGRectInset(self.bounds, kRingThickness, kRingThickness);
    CGPathRef result = [self newRoundRectPathForRect:interiorRect withRadius:kRoundButtonRadius];
    return result;
}


-(CGPathRef) newInteriorRingPahtWhileUsingRadialGradient:(BOOL)useRadialGradient
{
    CGRect interiorRect = useRadialGradient?self.bounds:CGRectInset(self.bounds, kRingThickness, kRingThickness);
    CGRect ringRect = CGRectInset(interiorRect, 3.0, 3.0);
    CGPathRef result = [self newRoundRectPathForRect:ringRect withRadius:kRoundButtonRadius-2];
    return result;
}

-(CGPathRef) newExteriorRingPath
{
    CGRect ringRect = CGRectInset(self.bounds, kRingThickness, kRingThickness);
    CGPathRef result = [self newRoundRectPathForRect:ringRect withRadius:kRoundButtonRadius];
    return result;
}


-(void) drawLayer:(CALayer *)layer inContext:(CGContextRef)quartzContext
{
    CGRect myBounds = layer.bounds;
    CGContextSaveGState(quartzContext);
    BOOL drawRing = YES;
    BOOL    inNormalMode = !self.selected;
    GHSegmentedControl* control = self.parentContent.control;
    ColorScheme scheme = control.scheme;
    
    
    CGContextSaveGState(quartzContext);
    CGContextClearRect(quartzContext, myBounds);
    
    if(scheme == kColorSchemeEmpty || scheme == kColorSchemeFlatAndBoxy || scheme == kColorSchemeTVOS) // approximate an iOS 7 segmented control
    {
        UIColor* baseColor = [self.parentContent selectedColor];
        
        CGContextSetStrokeColorWithColor(quartzContext, baseColor.CGColor);
        
        if(scheme == kColorSchemeTVOS)
        {
            if(self.isHighlighted)
            {
                CGContextSetFillColorWithColor(quartzContext, [UIColor whiteColor].CGColor);
            }
            else if(inNormalMode || !control.selected)
            {
                CGContextSetFillColorWithColor(quartzContext, control.backgroundColor.CGColor);
            }
            else
            {
                CGContextSetFillColorWithColor(quartzContext, baseColor.CGColor);
            }
            
            CGPathRef   boundingPath = [self newOutlinePathWhileUsingRadialGradient:YES];
            CGContextAddPath(quartzContext, boundingPath);
            CGContextDrawPath(quartzContext, kCGPathFill);
            CGPathRelease(boundingPath);
        }
        else
        {
            if(inNormalMode)
            {
                CGContextSetFillColorWithColor(quartzContext, control.backgroundColor.CGColor);
            }
            else
            {
                CGContextSetFillColorWithColor(quartzContext, baseColor.CGColor);
            }
            
            CGFloat lineWidth = 1/self.layer.contentsScale;
            
            CGContextSetLineWidth(quartzContext, lineWidth);
            if(scheme == kColorSchemeEmpty)
            {
                CGPathRef   boundingPath = [self newOutlinePathWhileUsingRadialGradient:NO];
                CGContextAddPath(quartzContext, boundingPath);
                CGContextDrawPath(quartzContext, kCGPathFillStroke);
                CGPathRelease(boundingPath);
            }
            else
            {
                CGContextAddRect(quartzContext, myBounds);
                CGContextDrawPath(quartzContext, kCGPathFillStroke);
            }
        }
    }
    else
    {
        CGPathRef   boundingPath = [self newOutlinePathWhileUsingRadialGradient:control.useRadialGradient];
        CGContextAddPath(quartzContext, boundingPath);
        CGGradientRef   gradientToUse = 0;
        if(self.selected)
        {
            gradientToUse = control.faceGradientSelected;
        }
        else if(self.isHighlighted)
        {
            gradientToUse = control.faceGradientPressed;
        }
        else
        {
            gradientToUse = control.faceGradient;
        }
        
        NSAssert((gradientToUse != 0), @"GHControl: Not setup properly");
        
        // draw subtly gradiented interior
        CGRect interiorRect = control.useRadialGradient?myBounds:CGRectInset(myBounds, kRingThickness, kRingThickness);
        
        if(control.showShadow)
        {
            drawRing = NO;
        }
        
        
        CGContextClip(quartzContext);
        
        CGPoint topPoint = myBounds.origin;
        CGPoint bottomPoint = CGPointMake(myBounds.origin.x, myBounds.origin.y+myBounds.size.height);
        if(control.useRadialGradient)
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
            CGPathRef interiorRingPath = [self newInteriorRingPahtWhileUsingRadialGradient:control.useRadialGradient];
            CGContextSetLineWidth(quartzContext, 1/self.layer.contentsScale);
            if(inNormalMode)
            {
                CGContextSetStrokeColorWithColor(quartzContext, [[UIColor darkGrayColor] colorWithAlphaComponent:0.5].CGColor);
            }
            else
            {
                CGContextSetStrokeColorWithColor(quartzContext, control.ringColor.CGColor);
            }
            CGContextAddPath(quartzContext, interiorRingPath);
            CGContextStrokePath(quartzContext);
            CGPathRelease(interiorRingPath);
            drawRing = NO;
        }
        else
        {
            CGContextDrawLinearGradient(quartzContext,gradientToUse, topPoint, bottomPoint, 0);
        }
        
        CGContextRestoreGState(quartzContext);
        
        CGPathRelease(boundingPath);
        if(drawRing)
        {
            CGPathRef exteriorRingPath = [self newExteriorRingPath];
            CGContextSetLineWidth(quartzContext, 1/self.layer.contentsScale);
            CGContextSetStrokeColorWithColor(quartzContext, control.ringColor.CGColor);
            
            CGContextAddPath(quartzContext, exteriorRingPath);
            CGContextStrokePath(quartzContext);
            CGPathRelease(exteriorRingPath);
        }
    }
    
    CGContextRestoreGState(quartzContext);
}

-(void) setSelected:(BOOL)selected
{
    if(selected != _selected)
    {
        _selected = selected;
        [self.layer setNeedsLayout];
        [self.layer setNeedsDisplay];
    }
}

-(void) setIsHighlighted:(BOOL)isHighlighted
{
    if(isHighlighted != _isHighlighted)
    {
        _isHighlighted = isHighlighted;
        [self.layer setNeedsLayout];
        [self.layer setNeedsDisplay];
        
    }
}

@end


@implementation GHSegmentDefinition

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height
{
    CGFloat result = self.width;
    if(result == 0)
    {
        if(self.renderer != nil)
        {
            CGSize intrinsicSize = self.renderer.viewRect.size;
            if(intrinsicSize.height && intrinsicSize.width && height)
            {
                result = (intrinsicSize.width/intrinsicSize.height) * height;
            }
        }
        else if(self.title.length)
        {
            UIFont* textFont = [GHSegmentedControlContentView titleFontForState:UIControlStateNormal];
            NSDictionary* fontAttributes = @{NSFontAttributeName:textFont};
            result = ceil([self.title sizeWithAttributes:fontAttributes].width);
            
        }
    }
    return result;
}

-(NSString*) accessibilityLabel
{
    NSString* result = _accessibilityLabel;
    if(result.length == 0)
    {
        result = self.title;
    }
    
    return result;
}

-(NSString*) description
{
    NSString* result = [NSString stringWithFormat:@"%@, enabled:%@ customWidth:%0.2f artInsetFraction:%0.2f title:'%@' renderer='%@'", NSStringFromClass([self class]), self.enabled?@"Yes":@"No", self.width, self.artInsetFraction, self.title, self.renderer.svgURL.lastPathComponent];
    
    
    return result;
}

@end

@interface GHSegmentedControl ()
@property(nonatomic, strong) NSArray* definitions; //GHSegmentDefinition
@end

@implementation GHSegmentedControlContentView

+(UIFont*) titleFontForState:(UIControlState)state
{
    UIFont* result = nil;
    NSDictionary* titleProperties = [[UISegmentedControl appearance] titleTextAttributesForState:state];
    if(titleProperties == nil) // iOS 9 stopped returning the titleProperties from UISegmentedControl appearance
    {
#if TARGET_OS_TV
        result = [UIFont systemFontOfSize:40 weight:UIFontWeightMedium];
#else
        result = [UIFont systemFontOfSize:14];
#endif
    }
    else
    {
        UIFontDescriptor* fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:titleProperties];
        result = [UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize];
    }
    return result;
}



-(NSInteger) indexOfTouch:(CGPoint)touchLocation
{
    NSInteger result = NSNotFound;
    NSInteger index = 0;
    for(UIView* aView in self.subviews)
    {
        if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
        {
            CGPoint viewsPoint = [self convertPoint:touchLocation toView:aView];
            if(CGRectContainsPoint(aView.bounds, viewsPoint))
            {
                result = index;
                break;
            }
            index++;
        }
    }
    
    return result;
}

-(CGRect) frameForSegmentAtIndex:(NSInteger)testIndex
{
    CGRect result = CGRectZero;
    NSInteger index = 0;
    for(UIView* aView in self.subviews)
    {
        if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
        {
            if(testIndex == index)
            {
                result = aView.frame;
                break;
            }
            index++;
        }
    }
    return result;
}


-(void) syncSubViewTypes
{
    NSArray<UIView *>* subViews = self.subviews;
    for (NSUInteger index = 0; index < subViews.count; index++) {
        GHSegmentedControlSegmentView* aSubview = (GHSegmentedControlSegmentView*)[subViews objectAtIndex:index];
        if(subViews.count == 1)
        {
            aSubview.segmentType = kSegmentTypeOnly;
        }
        else if(index == 0)
        {
            aSubview.segmentType = kSegmentTypeLeft;
        }
        else if(index == (subViews.count-1))
        {
            aSubview.segmentType = kSegmentTypeRight;
        }
        else
        {
            aSubview.segmentType = kSegmentTypeMiddle;
        }
    }
}

-(void) insertDefinition:(GHSegmentDefinition*)aDefinition atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    NSMutableArray* newDefinitions = (self.definitions.count)?[self.definitions mutableCopy]:[NSMutableArray new];
    GHSegmentedControlSegmentView* newView = [[GHSegmentedControlSegmentView alloc] initWithFrame:CGRectZero];
    newView.segmentDefinition = aDefinition;
    newView.parentContent = self;
    CGRect startRect = CGRectMake(0, 0, 0, self.bounds.size.height);
    if(newDefinitions.count == segment)
    {
        [newDefinitions addObject:aDefinition];
        startRect.origin.x = self.bounds.size.width;
        newView.frame = startRect;
        [self addSubview:newView];
    }
    else if (segment == 0)
    {
        newView.frame = startRect;
        [self insertSubview:newView atIndex:0];
    }
    else if(newDefinitions.count > segment)
    {
        [newDefinitions insertObject:aDefinition atIndex:segment];
        GHSegmentedControlSegmentView* leftSegmentLayer = (GHSegmentedControlSegmentView*)[self.subviews objectAtIndex:segment];
        startRect.origin.x = leftSegmentLayer.frame.origin.x+leftSegmentLayer.frame.size.width;
        
        newView.frame = startRect;
        [self insertSubview:newView atIndex:(unsigned)segment];
    }
    
    if(self.definitions.count <= segment)
    {
        self.definitions = [newDefinitions copy];
        [self syncSubViewTypes];
        [self setNeedsLayout];
    }
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated
{
    NSMutableArray* newDefinitions = (self.definitions.count)?[self.definitions mutableCopy]:[NSMutableArray new];
    if(segment < newDefinitions.count)
    {
        [newDefinitions removeObjectAtIndex:segment];
        NSArray<UIView*>* subViews = self.subviews;
        if(subViews.count > segment)
        {
            UIView* viewToRemove = [subViews objectAtIndex:segment];
            [viewToRemove removeFromSuperview];
        }
        [self setNeedsLayout];
    }
}

-(void) updateSegmentAtIndex:(NSUInteger)segment withDefinition:(GHSegmentDefinition*)newDefinition
{
    NSMutableArray* newDefinitions = (self.definitions.count)?[self.definitions mutableCopy]:[NSMutableArray new];
    if(segment < newDefinitions.count)
    {
        [newDefinitions replaceObjectAtIndex:segment withObject:newDefinition];
    }
    [self setNeedsLayout];
}

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height
{
    CGFloat result = 0.0;
    
    if(self.control.apportionsSegmentWidthsByContent)
    {
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            CGFloat segmentWidth = [aDefinition preferredWidthGivenHeight:height];
            result += segmentWidth;
        }
    }
    else
    {
        CGFloat maxWidth = 0.0;
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            maxWidth = fmaxf(maxWidth,[aDefinition preferredWidthGivenHeight:height]);
        }
        result += (maxWidth * self.definitions.count);
    }
    return result;
}

-(void) setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    _selectedSegmentIndex = selectedSegmentIndex;
    _trackedSegmentIndex = NSNotFound;
    [self syncSelectedIndex];
    
}

-(void) setTrackedSegmentIndex:(NSUInteger)trackedSegmentIndex
{
    if(trackedSegmentIndex != _trackedSegmentIndex)
    {
        _trackedSegmentIndex = trackedSegmentIndex;
        [self syncTrackedIndex];
    }
}

-(void) syncTrackedIndex
{
    NSInteger index = 0;
    for(UIView* aView in self.subviews)
    {
        if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
        {
            GHSegmentedControlSegmentView* segmentView = (GHSegmentedControlSegmentView*)aView;
            UIColor* currentColor = nil;
            if(self.trackedSegmentIndex == index)
            {
                currentColor = [self.control textColorPressed];
                segmentView.isHighlighted = YES;
            }
            else
            {
                currentColor = [self.control textColor];
                segmentView.isHighlighted = NO;
            }
            segmentView.currentColor = currentColor;
            index++;
        }
    }

}

-(void) syncSelectedIndex
{
    NSInteger index = 0;
    for(UIView* aView in self.subviews)
    {
        if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
        {
            GHSegmentedControlSegmentView* segmentView = (GHSegmentedControlSegmentView*)aView;
            UIColor* currentColor = nil;
            if(self.selectedSegmentIndex == index)
            {
                currentColor = [self.control textColorSelected];
                segmentView.selected = YES;
            }
            else
            {
                currentColor = [self.control textColor];
                segmentView.selected = NO;
            }
            segmentView.currentColor = currentColor;
            index++;
        }
    }
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    if(self.subviews.count == 0)
    {
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            GHSegmentedControlSegmentView* newView = [[GHSegmentedControlSegmentView alloc] initWithFrame:CGRectZero];
            newView.segmentDefinition = aDefinition;
            newView.parentContent = self;
            [self addSubview:newView];
        }
        [self syncSubViewTypes];
        [self syncSelectedIndex];
    }
    CGFloat x = 0.0;
    CGFloat wantedWidth = [self preferredWidthGivenHeight:self.bounds.size.height];
    CGFloat extraWidth = floor(self.bounds.size.width - wantedWidth);
    CGFloat extraWidthPerSegment = floor((self.definitions.count > 0)?extraWidth/self.definitions.count:0.0);
    
    for(GHSegmentedControlSegmentView* aView in self.subviews)
    {
        if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
        {
            CGFloat segmentWidth = floor([aView.segmentDefinition preferredWidthGivenHeight:self.bounds.size.height] + extraWidthPerSegment);
            CGRect segmentFrame = CGRectMake(x, 0, segmentWidth, self.bounds.size.height);
            aView.frame = segmentFrame;
            x += floor(segmentWidth);
            [aView setNeedsDisplay];
        }
    }
    if(x < self.bounds.size.width && self.subviews.count)
    {
        CGFloat extra = self.bounds.size.width-x;
        CGFloat extraPer = floor(extra/self.subviews.count);
        CGFloat remainder = extra-extraPer*self.subviews.count;
        x = 0.0;
        for(GHSegmentedControlSegmentView* aView in self.subviews)
        {
            if([aView isKindOfClass:[GHSegmentedControlSegmentView class]])
            {
                CGRect newViewFrame = aView.frame;
                newViewFrame.origin.x = x;
                newViewFrame.size.width += extraPer;
                if(remainder >= 1.0)
                {
                    newViewFrame.size.width += 1.0;
                    remainder -= 1.0;
                }
                x = newViewFrame.origin.x+newViewFrame.size.width;
                aView.frame = newViewFrame;
                [aView setNeedsDisplay];
            }
        }
    }
}

-(UIColor*) selectedColor
{
    UIColor* result = nil;
    if([self.control respondsToSelector:@selector(tintColor)])
    {
        result = self.control.tintColor;
    }
    if(result == nil)
    {
        result = self.control.textColor;
        if(result == nil)
        {
            result = [GHControlFactory newTextColorForScheme:self.control.scheme];
        }
    }
    return result;

}

-(void)drawRect:(CGRect)rect
{
}

@end


@implementation GHSegmentedControl

+(void)makeSureLoaded
{
}

-(void)setupForScheme:(NSUInteger)aScheme
{
    [super setupForScheme:aScheme];
    [self setNeedsDisplay];
    [self setNeedsLayout];
    self.layer.opaque = NO;
}


- (instancetype) initWithFrame:(CGRect)frame
{
    if(nil != (self = [super initWithFrame:frame]))
    {
    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if(nil != (self = [super initWithCoder:aDecoder]))
    {
    }
    return self;
}

- (instancetype)initWithItems:(NSArray *)items
{
    if(nil != (self = [super init]))
    {
        NSMutableArray* newDefinitions = [[NSMutableArray alloc] initWithCapacity:items.count];
        for(NSObject* anItem in items)
        {
            GHSegmentDefinition* aDefinition = [[GHSegmentDefinition alloc] init];
            aDefinition.enabled = YES;
            if([anItem isKindOfClass:[NSString class]])
            {
                aDefinition.title = (NSString*)anItem;
            }
            else if([anItem isKindOfClass:[SVGRenderer class]])
            {
                aDefinition.renderer = (SVGRenderer*)anItem;
                aDefinition.artInsetFraction = self.artInsetFraction;
            }
            else
            {
                NSLog(@"Unexpected Item for GHSegmentedControl: %@", NSStringFromClass([anItem class]));
                aDefinition = nil;
            }
            if(aDefinition != nil)
            {
                [newDefinitions addObject:aDefinition];
            }
        }
        _definitions = [newDefinitions copy];
    }
    return self;
}

+(NSString*) placeholderButterflySVG
{
    NSString* result = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <svg x=\"0px\" height=\"120\" viewport-fill=\"none\" y=\"0px\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"138\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"-25, 0, 138, 120\"> <g stroke=\"black\" xml:id=\"LAYER\" vector-effect=\"non-scaling-stroke\" stroke-width=\"0.5\" fill=\"currentColor\" stroke-linecap=\"round\" transform=\"translate(0,15)\"> <path xml:id=\"PATH\" d=\"M44 42C38 29 42 8 5 5 13 53 14 42 21 47-18 113 43 92 45 66 45 59 45 47 44 42ZM55 66C57 92 106 109 79 47 86 42 87 53 95 5 58 8 62 29 56 42 55 47 55 47 55 66z\"/> <path fill=\"black\" stroke=\"none\" d=\"M56 42A7 7 0 1 0 44 42C45 47 46 59 47 66Q50 95 53 66C54 59 55 47 56 42ZM45 33.5Q46 24 37 15 A1 1 0 1 1 37.5 14.5Q45 19 46 32.5ZM55 33.5Q54 24 63 15A1 1 0 1 0 62.5 14.5Q55 20 54 32.5Z\" /> </g> </svg>";
    return result;
}

- (void)prepareForInterfaceBuilder
{
    
    GHSegmentDefinition* definition0 = [GHSegmentDefinition new];
    definition0.enabled = YES;
    definition0.title = NSLocalizedString(@"Add Segments", @"");
    
    GHSegmentDefinition* definition1 = [GHSegmentDefinition new];
    definition1.enabled = YES;
    definition1.title = NSLocalizedString(@"In Code", @"");
    
    GHSegmentDefinition* definition2 = [GHSegmentDefinition new];
    definition2.enabled = YES;
    
    SVGRenderer* butterflyRenderer = [[SVGRenderer alloc] initWithString:[GHSegmentedControl placeholderButterflySVG]];
    definition2.renderer = butterflyRenderer;
    
    
    if(self.bounds.size.width > 0)
    {
        CGFloat perWidth = self.bounds.size.width/3.0;
        definition0.width = perWidth;
        definition1.width = perWidth;
        definition2.width = perWidth;
    }
    self.definitions = @[definition0, definition1, definition2];
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    if(segment <= self.definitions.count)
    {
        NSMutableArray* mutableDefinitions = (self.definitions == nil)?[NSMutableArray new]:[self.definitions mutableCopy];
        GHSegmentDefinition* newDefinition = [GHSegmentDefinition new];
        newDefinition.enabled = YES;
        newDefinition.title = title;
        
        [mutableDefinitions insertObject:newDefinition atIndex:segment];
        if(animated)
        {
            _definitions = [mutableDefinitions copy];
            [self.contentView insertDefinition:newDefinition atIndex:segment animated:animated];
        }
        else
        {
            self.definitions =[mutableDefinitions copy];
        }
    }
}

- (void)insertSegmentWithRenderer:(SVGRenderer *)renderer  atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    if(segment <= self.definitions.count)
    {
        [self insertSegmentWithRenderer:renderer accessibilityLabel:nil atIndex:segment animated:animated];
    }
}

-(void) invalidateAccessibility
{
    if([NSObject instancesRespondToSelector:@selector(setAccessibilityElements:)])
    {
        if([super accessibilityElements].count > 0)
        {
            [super setAccessibilityElements:nil];
        }
    }
}

-(NSUInteger) numberOfSegments
{
    return self.definitions.count;
}

- (void)insertSegmentWithRenderer:(SVGRenderer *)renderer accessibilityLabel:(nullable NSString*)accessibilityLabel  atIndex:(NSUInteger)segment animated:(BOOL)animated;
{
    if(segment <= self.definitions.count)
    {
        NSMutableArray* mutableDefinitions = (self.definitions == nil)?[NSMutableArray new]:[self.definitions mutableCopy];
        GHSegmentDefinition* newDefinition = [GHSegmentDefinition new];
        newDefinition.enabled = YES;
        newDefinition.accessibilityLabel = accessibilityLabel;
        newDefinition.renderer = renderer;
        newDefinition.artInsetFraction = self.artInsetFraction;
        
        [mutableDefinitions insertObject:newDefinition atIndex:segment];
        if(animated)
        {
            _definitions = [mutableDefinitions copy];
            [self.contentView insertDefinition:newDefinition atIndex:segment animated:animated];
        }
        else
        {
            self.definitions = [mutableDefinitions copy];
        }
        [self invalidateAccessibility];
    }
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated
{
    if(segment < self.definitions.count && self.definitions != nil)
    {
        NSMutableArray* mutableDefinitions = [self.definitions mutableCopy];
        [mutableDefinitions removeObjectAtIndex:segment];
        if(animated)
        {
            _definitions = [mutableDefinitions copy];
            [self.contentView removeSegmentAtIndex:segment animated:YES];
        }
        else
        {
            self.definitions =[mutableDefinitions copy];
        }
        [self invalidateAccessibility];
    }
}


- (void)removeAllSegments
{
    self.definitions = [NSArray new];
    
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment
{
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        definition.renderer = nil;
        definition.title = title;
        [self.contentView updateSegmentAtIndex:segment withDefinition:definition];
    }
    [self invalidateAccessibility];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment
{
    NSString* result = nil;
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        result = definition.title;
    }
    
    return result;
}

-(void) setRenderer:(SVGRenderer *)renderer forSegmentedIndex:(NSUInteger)segment
{
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        definition.title = nil;
        definition.renderer = renderer;
        [self.contentView updateSegmentAtIndex:segment withDefinition:definition];
    }
    [self invalidateAccessibility];
}

-(SVGRenderer*) rendererForSegmentedIndex:(NSUInteger)segment
{
    SVGRenderer* result = nil;
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        result = definition.renderer;
    }
    
    return result;
}

-(void) setAccessibilityLabel:(NSString *)accessibilityLabel forSegmentIndex:(NSUInteger)segment
{
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        definition.accessibilityLabel = accessibilityLabel;
        [self.contentView updateSegmentAtIndex:segment withDefinition:definition];
    }
    [self invalidateAccessibility];
}

-(nullable NSString*)accessibilityLabelForSegmentedIndex:(NSUInteger)segment
{
    NSString* result = nil;
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        result = definition.accessibilityLabel;
    }
    
    return result;
}

- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)segment
{
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        definition.width = width;
        [self.contentView updateSegmentAtIndex:segment withDefinition:definition];
    }
}

-(CGFloat) widthForSegmentAtIndex:(NSUInteger)segment
{
    CGFloat result = 0.0;
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        result = definition.width;
    }
    return result;
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment
{
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        definition.enabled = enabled;
        [self.contentView updateSegmentAtIndex:segment withDefinition:definition];
        
        NSArray* accessibilityElements = [super accessibilityElements];
        if(accessibilityElements.count > segment)
        {
            GHSegmentedControlAccessibilityWrapper* aWrapper = [accessibilityElements objectAtIndex:segment];
            if(enabled)
            {
                aWrapper.accessibilityTraits &= ~UIAccessibilityTraitNotEnabled;
            }
            else
            {
                aWrapper.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
            }
        }
    }
}

-(BOOL) isEnabledForSegmentAtIndex:(NSUInteger)segment
{
    BOOL result = NO;
    if(segment < self.definitions.count)
    {
        GHSegmentDefinition* definition = [self.definitions objectAtIndex:segment];
        result = definition.enabled;
    }
    return result;
}


- (CGSize)intrinsicContentSize
{
    UIFont* font = [GHSegmentedControlContentView titleFontForState:UIControlStateNormal];
    CGSize result = CGSizeMake(kContentMargin*2.0, font.lineHeight+kContentMargin*2.0);
    if(self.apportionsSegmentWidthsByContent)
    {
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            result.width += [aDefinition preferredWidthGivenHeight:result.height];
        }
    }
    else
    {
        CGFloat maxWidth = 0.0;
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            maxWidth = fmaxf(maxWidth,[aDefinition preferredWidthGivenHeight:result.height]);
        }
        result.width += (maxWidth * self.definitions.count);
    }
    
    if(self.definitions.count > 1)
    {
        result.width += (self.definitions.count-1)*kContentMargin;
    }
    
    return result;
}

-(GHSegmentedControlContentView*)contentView
{
    GHSegmentedControlContentView* result = _contentView;
    if(result == nil)
    {
        _contentView = result = [[GHSegmentedControlContentView alloc] initWithFrame:self.bounds];
        result.control = self;
        result.opaque = NO;
        result.backgroundColor = [UIColor clearColor];
        result.userInteractionEnabled = NO;
        result.definitions = self.definitions;
        [result setNeedsLayout];
        self.opaque = NO;
        [self addSubview:result];
    }
    return result;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    self.contentView.frame = self.bounds;
    [self.contentView setNeedsDisplay];
    [self.contentView setNeedsLayout];
}


-(void) setDefinitions:(NSArray *)definitions
{
    _definitions = definitions;
    self.contentView.definitions = definitions;
    if([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
    {
        [self invalidateIntrinsicContentSize];
    }
}

-(void) setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    _selectedSegmentIndex = selectedSegmentIndex;
    self.contentView.selectedSegmentIndex = selectedSegmentIndex;
    NSArray* accessibilityElements = [super accessibilityElements];
    if(accessibilityElements.count > selectedSegmentIndex)
    {
        for(GHSegmentedControlAccessibilityWrapper* aWrapper in accessibilityElements)
        {
            if(aWrapper.index == selectedSegmentIndex)
            {
                aWrapper.accessibilityTraits |= UIAccessibilityTraitSelected;
            }
            else
            {
                aWrapper.accessibilityTraits &= ~ UIAccessibilityTraitSelected;
            }
        }
    }
}



-(NSInteger) indexOfTouch:(CGPoint)touchLocation
{
    NSInteger result = [self.contentView indexOfTouch:touchLocation];
    return result;
}


-(void) updateTracking:(UITouch*)touch
{
    CGPoint localPoint = [touch locationInView:self];
    NSInteger hitSegment = [self.contentView indexOfTouch:localPoint];
    
    if(self.contentView.trackedSegmentIndex != hitSegment)
    {
        self.contentView.trackedSegmentIndex = hitSegment;
    }
}

#if !TARGET_OS_TV

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL result = [super beginTrackingWithTouch:touch withEvent:event];
    [self updateTracking:touch];
    
    return result;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL result = [super continueTrackingWithTouch:touch withEvent:event];
    [self updateTracking:touch];
    
    return result;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSInteger trackedSegmentIndex = self.contentView.trackedSegmentIndex;
    if(trackedSegmentIndex == NSNotFound)
    {
    }
    else if(trackedSegmentIndex != self.contentView.selectedSegmentIndex)
    {
        self.selectedSegmentIndex = trackedSegmentIndex;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if(trackedSegmentIndex == self.contentView.selectedSegmentIndex)
    {
        self.selectedSegmentIndex = trackedSegmentIndex;
    }
    self.contentView.trackedSegmentIndex = NSNotFound;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    self.contentView.trackedSegmentIndex = NSNotFound;
    [super cancelTrackingWithEvent:event];
}
#endif

- (BOOL)isAccessibilityElement
{
    return NO;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

- (NSInteger)accessibilityElementCount
{
    NSInteger result = self.definitions.count;
    return result;
}

-(NSString*) accessibilityLabel
{
    NSString* result = [super accessibilityLabel];
    
    return result;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index
{
    GHSegmentedControlAccessibilityWrapper* result = nil;
    if(index >= 0 && index < self.definitions.count)
    {
        result = [[GHSegmentedControlAccessibilityWrapper alloc] initWithAccessibilityContainer:self];
        CGRect localFrame = [self.contentView frameForSegmentAtIndex:index];
        result.accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(localFrame, self);
        result.index = index;
        result.segmentDefinition = [self.definitions objectAtIndex:index];
        result.accessibilityLabel = result.segmentDefinition.accessibilityLabel;
        result.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction | UIAccessibilityTraitUpdatesFrequently;
        result.isAccessibilityElement = YES;
        result.accessibilityHint = [[[NSNumber numberWithUnsignedInteger:index+1].stringValue stringByAppendingString:NSLocalizedString(@" of " , @"")] stringByAppendingString:[NSNumber numberWithUnsignedInteger:self.definitions.count].stringValue];
        if(index == self.selectedSegmentIndex)
        {
            result.accessibilityTraits |= UIAccessibilityTraitSelected;
        }
        
        if(!self.enabled)
        {
            result.accessibilityTraits |= UIAccessibilityTraitNotEnabled;
        }
    }
    return result;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
    NSInteger result = NSNotFound;
    if([element isKindOfClass:[GHSegmentedControlAccessibilityWrapper class]])
    {
        GHSegmentedControlAccessibilityWrapper* wrapper = element;
        
        result = wrapper.index;
    }
    return result;
}

-(NSArray*) accessibilityElements
{
    NSArray* result = [super accessibilityElements];
    if(result == nil)
    {
        NSMutableArray* mutableResult = [[NSMutableArray alloc] initWithCapacity:self.definitions.count];
        for(NSUInteger index = 0; index < self.definitions.count; index++)
        {
            GHSegmentedControlAccessibilityWrapper* aWrapper = [self accessibilityElementAtIndex:index];
            [mutableResult addObject:aWrapper];
        }
        result = [mutableResult copy];
        [self setAccessibilityElements:result];
    }
    return result;
}

- (void)accessibilityIncrement
{
    if(self.selectedSegmentIndex < self.definitions.count-1)
    {
        [self setSelectedSegmentIndex:self.selectedSegmentIndex+1];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)accessibilityDecrement
{
    if(self.selectedSegmentIndex > 0 && self.definitions.count > 0)
    {
        [self setSelectedSegmentIndex:self.selectedSegmentIndex-1];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

-(void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGContextClearRect(ctx, self.bounds);
}

-(void)drawRect:(CGRect)rect
{
}

@end

@implementation GHSegmentedControlAccessibilityWrapper


-(CGRect) accessibilityFrame
{
    CGRect result = [super accessibilityFrame];
    if([self.accessibilityContainer isKindOfClass:[GHSegmentedControl class]])
    {
        GHSegmentedControl* myControl = self.accessibilityContainer;
        CGRect localFrame = [myControl.contentView frameForSegmentAtIndex:self.index];
        result = UIAccessibilityConvertFrameToScreenCoordinates(localFrame, myControl);;
    }
    
    return result;
}
@end


#if TARGET_OS_TV
#pragma mark tvOS
@interface GHSegmentedControl(tvOS)
@end

@interface GHSegmentedControlContentView(tvOS)
-(void) syncFocus;
@end

@interface GHSegmentedControlSegmentView (tvOS)

@end

@implementation GHSegmentedControlSegmentView(tvOS)

-(BOOL) canBecomeFocused
{
    return self.parentContent.control.enabled;
}

- (void)updateFocusIfNeeded
{
    
    [self setNeedsDisplay];
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
    BOOL result =  NO;
    if(context.nextFocusedView == self)
    {
        result = YES;
        self.layer.shadowOffset = CGSizeMake(0, 10);
        self.layer.shadowOpacity = 0.6;
        self.layer.shadowRadius = 15;
        self.layer.cornerRadius = 6.0;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        if(context.focusHeading == UIFocusHeadingRight)
        {
            [self.parentContent.control accessibilityIncrement];
            [self.parentContent.control setNeedsFocusUpdate];
        }
        else if(context.focusHeading == UIFocusHeadingLeft)
        {
            [self.parentContent.control accessibilityDecrement];
            [self.parentContent.control setNeedsFocusUpdate];
        }
        self.isHighlighted = self.selected;
        [self setNeedsDisplay];
        [self.parentContent syncFocus];
    }
    else
    {
        self.isHighlighted = NO;
        result = [super shouldUpdateFocusInContext:context];
    }
    
    BOOL resetPrevious =  (self != context.nextFocusedView && self == context.previouslyFocusedView) ||
                    (self != context.previouslyFocusedView && [context.previouslyFocusedView isKindOfClass:[self class]]);
    
    if(resetPrevious)
    {
        GHSegmentedControlSegmentView* previousView = (GHSegmentedControlSegmentView*)context.previouslyFocusedView;
        previousView.layer.shadowOffset = CGSizeMake(0, 0);
        previousView.layer.shadowOpacity = 0.;
        previousView.layer.shadowRadius = 0;
        previousView.layer.cornerRadius = 0.0;
        previousView.isHighlighted = NO;
        [previousView setNeedsDisplay];
    }
    
    
    return result;
}

@end


@implementation GHSegmentedControlContentView(tvOS)
-(void) syncFocus
{
    NSInteger whichIndex = 0;
    NSInteger selectedIndex = self.control.selectedSegmentIndex;
    for(GHSegmentedControlSegmentView* segmentView in self.subviews)
    {
        CALayer* viewsLayer = segmentView.layer;
        if(whichIndex == selectedIndex)
        {
            viewsLayer.shadowOffset = CGSizeMake(0, 10);
            viewsLayer.shadowOpacity = 0.6;
            viewsLayer.shadowRadius = 15;
            viewsLayer.cornerRadius = 6.0;
            viewsLayer.shadowColor = [UIColor blackColor].CGColor;
            if(!segmentView.isHighlighted)
            {
                segmentView.isHighlighted = YES;
                [segmentView setNeedsDisplay];
            }
        }
        else
        {
            if(segmentView.isHighlighted)
            {
                segmentView.isHighlighted = NO;
                [segmentView setNeedsDisplay];
            }
            viewsLayer.shadowOffset = CGSizeMake(0, 0);
            viewsLayer.shadowOpacity = 0.;
            viewsLayer.shadowRadius = 0;
            viewsLayer.cornerRadius = 0.0;
        }
        whichIndex++;
    }
}


-(UIView*) preferredFocusedView
{
    UIView* result = nil;
    
    if(self.selectedSegmentIndex == NSNotFound)
    {
        if(self.canBecomeFocused && self.subviews.count)
        {
            result = [self.subviews objectAtIndex:0];
        }
    }
    else
    {
        result = [self.subviews objectAtIndex:self.selectedSegmentIndex];
    }
    
    return result;
}

@end

@implementation GHSegmentedControl(tvOS)
-(BOOL) canBecomeFocused
{
    return self.enabled;
}


-(UIView*) preferredFocusedView
{
    return self.contentView.preferredFocusedView;
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
    BOOL result =  NO;
    if(context.nextFocusedView == self)
    {
        result = YES;
    }
    else
    {
        result = [super shouldUpdateFocusInContext:context];
    }
    
    return result;
}


-(void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
}

-(void) pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    for(GHSegmentedControlSegmentView* aView in self.contentView.subviews)
    {
        aView.layer.shadowOpacity = 0.0;
    }
    
}

-(void) pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    for(GHSegmentedControlSegmentView* aView in self.contentView.subviews)
    {
        aView.layer.shadowOpacity = 1.0;
    }
    self.beingPressed = NO;
}

- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(nullable UIPressesEvent *)event
{
    for(GHSegmentedControlSegmentView* aView in self.contentView.subviews)
    {
        aView.layer.shadowOpacity = 1.0;
    }
    self.beingPressed = NO;
}

@end

#endif

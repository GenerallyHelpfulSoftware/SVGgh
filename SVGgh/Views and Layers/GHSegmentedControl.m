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



@interface GHSegmentDefinition : NSObject
@property(nonatomic, strong) NSString* title;
@property(nonatomic, strong) NSString* accessibilityLabel;
@property(nonatomic, strong) SVGRenderer* renderer;
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) CGFloat width; // 0.0 means automatic
@property(nonatomic, assign) CGFloat artInsetFraction;

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height;

@end

@interface GHSegmentedControlLayer : CALayer
@property(nonatomic, strong) NSArray* definitions; //GHSegmentDefinition
@property(nonatomic,getter=isMomentary) BOOL momentary;
@property(nonatomic,readonly) NSUInteger numberOfSegments;
@property(nonatomic) NSInteger selectedSegmentIndex;
@property(nonatomic, assign) NSUInteger trackedSegmentIndex;
@property(nonatomic, weak) GHSegmentedControl* control;

+(UIFont*) titleFontForState:(UIControlState)state;

@end

typedef enum GHSegmentType
{
    kSegmentTypeRight,
    kSegmentTypeMiddle,
    kSegmentTypeLeft,
    kSegmentTypeOnly
}GHSegmentType;

@interface GHSegmentedControlSegmentLayer : CALayer
@property(nonatomic, assign) enum GHSegmentType segmentType;
@property(nonatomic, strong) GHSegmentDefinition* segmentDefinition;
@property(nonatomic, weak) CALayer* contentLayer;
@property(nonatomic, strong) UIColor* currentColor;
@property(nonatomic, assign) BOOL selected;
@property(nonatomic, assign) BOOL isHighlighted;

-(CGFloat) preferredWidthGivenHeight:(CGFloat)height;

@end

@interface GHSegmentedControlAccessibilityWrapper : UIAccessibilityElement
@property(nonatomic, strong) GHSegmentDefinition* segmentDefinition;
@property(nonatomic, assign) NSInteger index;

@end



@implementation GHSegmentedControlSegmentLayer

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
        [self setNeedsDisplay];
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

-(void) layoutSublayers
{
    if(self.contentLayer == nil)
    {
        if(self.segmentDefinition.renderer != nil)
        {
            SVGRendererLayer* contentLayer = [[SVGRendererLayer alloc] init];
            contentLayer.renderer = self.segmentDefinition.renderer;
            contentLayer.contentsGravity = kCAGravityResizeAspect;
            contentLayer.defaultColor = self.currentColor;
            [self addSublayer:contentLayer];
            self.contentLayer = contentLayer;
        }
        else if(self.segmentDefinition.title.length)
        {
            CATextLayer* contentLayer = [[CATextLayer alloc] init];
            contentLayer.string = self.segmentDefinition.title;
            contentLayer.truncationMode = kCATruncationEnd;
            UIFont* textFont = [GHSegmentedControlLayer titleFontForState:UIControlStateNormal];
            NSString* fontName = textFont.fontName;
            CFStringRef fontNameCF = (__bridge CFStringRef)(fontName);
            CGFontRef fontCG = CGFontCreateWithFontName(fontNameCF);
            contentLayer.font = fontCG;
            CGFontRelease(fontCG);
            contentLayer.fontSize = textFont.pointSize;
            contentLayer.foregroundColor = self.currentColor?self.currentColor.CGColor:[UIColor blackColor].CGColor;
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
    
    if(self.segmentDefinition.artInsetFraction > 0)
    {
        inset = self.bounds.size.height*self.segmentDefinition.artInsetFraction;
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
            UIFont* textFont = [GHSegmentedControlLayer titleFontForState:UIControlStateNormal];
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

@implementation GHSegmentedControlLayer

+(UIFont*) titleFontForState:(UIControlState)state
{
    UIFont* result = nil;
    NSDictionary* titleProperties = [[UISegmentedControl appearance] titleTextAttributesForState:state];
    if(titleProperties == nil) // iOS 9 stopped returning the titleProperties from UISegmentedControl appearance
    {
        result = [UIFont systemFontOfSize:14];
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
    for(CALayer* aLayer in self.sublayers)
    {
        if([aLayer isKindOfClass:[GHSegmentedControlSegmentLayer class]])
        {
            CGPoint layersPoint = [self convertPoint:touchLocation toLayer:aLayer];
            if([aLayer containsPoint:layersPoint])
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
    for(CALayer* aLayer in self.sublayers)
    {
        if([aLayer isKindOfClass:[GHSegmentedControlSegmentLayer class]])
        {
            if(testIndex == index)
            {
                result = aLayer.frame;
                break;
            }
            index++;
        }
    }
    return result;
}


-(void) syncSubLayerTypes
{
    NSArray* subLayers = self.sublayers;
    for (NSUInteger index = 0; index < subLayers.count; index++) {
        GHSegmentedControlSegmentLayer* aSubLayer = [subLayers objectAtIndex:index];
        if(subLayers.count == 1)
        {
            aSubLayer.segmentType = kSegmentTypeOnly;
        }
        else if(index == 0)
        {
            aSubLayer.segmentType = kSegmentTypeLeft;
        }
        else if(index == (subLayers.count-1))
        {
            aSubLayer.segmentType = kSegmentTypeRight;
        }
        else
        {
            aSubLayer.segmentType = kSegmentTypeMiddle;
        }
    }
}

-(void) insertDefinition:(GHSegmentDefinition*)aDefinition atIndex:(NSUInteger)segment animated:(BOOL)animated
{
    NSMutableArray* newDefinitions = (self.definitions.count)?[self.definitions mutableCopy]:[NSMutableArray new];
    GHSegmentedControlSegmentLayer* newLayer = [[GHSegmentedControlSegmentLayer alloc] init];
    newLayer.segmentDefinition = aDefinition;
    newLayer.delegate = self;
    CGRect startRect = CGRectMake(0, 0, 0, self.bounds.size.height);
    if(newDefinitions.count == segment)
    {
        [newDefinitions addObject:aDefinition];
        startRect.origin.x = self.bounds.size.width;
        newLayer.frame = startRect;
        [self addSublayer:newLayer];
    }
    else if (segment == 0)
    {
        newLayer.frame = startRect;
        [self insertSublayer:newLayer atIndex:0];
    }
    else if(newDefinitions.count > segment)
    {
        [newDefinitions insertObject:aDefinition atIndex:segment];
        GHSegmentedControlSegmentLayer* leftSegmentLayer = (GHSegmentedControlSegmentLayer*)[self.sublayers objectAtIndex:segment];
        startRect.origin.x = leftSegmentLayer.frame.origin.x+leftSegmentLayer.frame.size.width;
        
        newLayer.frame = startRect;
        [self insertSublayer:newLayer atIndex:(unsigned)segment];
    }
    
    if(self.definitions.count <= segment)
    {
        self.definitions = [newDefinitions copy];
        [self syncSubLayerTypes];
        [self setNeedsLayout];
    }
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated
{
    NSMutableArray* newDefinitions = (self.definitions.count)?[self.definitions mutableCopy]:[NSMutableArray new];
    if(segment < newDefinitions.count)
    {
        [newDefinitions removeObjectAtIndex:segment];
        NSArray* subLayers = self.sublayers;
        if(subLayers.count > segment)
        {
            CALayer* layerToRemove = [subLayers objectAtIndex:segment];
            [layerToRemove removeFromSuperlayer];
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
    [self syncSelectedIndex];
    
}

-(void) syncSelectedIndex
{
    NSInteger index = 0;
    for(CALayer* aLayer in self.sublayers)
    {
        if([aLayer isKindOfClass:[GHSegmentedControlSegmentLayer class]])
        {
            GHSegmentedControlSegmentLayer* segmentLayer = (GHSegmentedControlSegmentLayer*)aLayer;
            UIColor* currentColor = nil;
            if(self.selectedSegmentIndex == index)
            {
                currentColor = [self.control textColorPressed];
                segmentLayer.selected = YES;
            }
            else
            {
                currentColor = [self.control textColor];
                segmentLayer.selected = NO;
            }
            segmentLayer.currentColor = currentColor;
            index++;
        }
    }
}

-(void) layoutSublayers
{
    if(self.sublayers.count == 0)
    {
        for(GHSegmentDefinition* aDefinition in self.definitions)
        {
            GHSegmentedControlSegmentLayer* newLayer = [[GHSegmentedControlSegmentLayer alloc] init];
            newLayer.segmentDefinition = aDefinition;
            newLayer.delegate = self;
            newLayer.contentsScale = self.contentsScale;
            newLayer.delegate = self;
            [self addSublayer:newLayer];
        }
        [self syncSubLayerTypes];
        [self syncSelectedIndex];
    }
    CGFloat x = 0.0;
    CGFloat wantedWidth = [self preferredWidthGivenHeight:self.bounds.size.height];
    CGFloat extraWidth = floor(self.bounds.size.width - wantedWidth);
    CGFloat extraWidthPerSegment = floor((self.definitions.count > 0)?extraWidth/self.definitions.count:0.0);
    
    for(GHSegmentedControlSegmentLayer* aLayer in self.sublayers)
    {
        if([aLayer isKindOfClass:[GHSegmentedControlSegmentLayer class]])
        {
            CGFloat segmentWidth = floor([aLayer.segmentDefinition preferredWidthGivenHeight:self.bounds.size.height] + extraWidthPerSegment);
            CGRect segmentFrame = CGRectMake(x, 0, segmentWidth, self.bounds.size.height);
            aLayer.frame = segmentFrame;
            x += floor(segmentWidth);
            
            [aLayer setNeedsDisplay];
            [aLayer setNeedsLayout];
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

- (void)drawLayer:(GHSegmentedControlSegmentLayer *)layer inContext:(CGContextRef)quartzContext
{
    CGRect layerBounds = layer.bounds;
    CGContextSaveGState(quartzContext);
    BOOL drawRing = YES;
    BOOL    inNormalMode = !layer.selected;
    ColorScheme scheme = self.control.scheme;
    
    
    CGContextSaveGState(quartzContext);
    
    if(scheme == kColorSchemeEmpty || scheme == kColorSchemeFlatAndBoxy) // approximate an iOS 7 segmented control
    {
        UIColor* baseColor = [self selectedColor];
        
        CGContextSetStrokeColorWithColor(quartzContext, baseColor.CGColor);
        if(inNormalMode)
        {
            CGContextSetFillColorWithColor(quartzContext, self.control.backgroundColor.CGColor);
        }
        else
        {
            CGContextSetFillColorWithColor(quartzContext, baseColor.CGColor);
        }
        CGFloat lineWidth = 1/self.contentsScale;
        
        CGContextSetLineWidth(quartzContext, lineWidth);
        if(scheme == kColorSchemeEmpty)
        {
            CGPathRef   boundingPath = [layer newOutlinePathWhileUsingRadialGradient:NO];
            CGContextAddPath(quartzContext, boundingPath);
            CGContextDrawPath(quartzContext, kCGPathFillStroke);
            CGPathRelease(boundingPath);
        }
        else
        {
            CGRect drawBounds = CGRectInset(layerBounds, 0, 0);
            CGContextAddRect(quartzContext, drawBounds);
            CGContextDrawPath(quartzContext, kCGPathFillStroke);
        }
    }
    else
    {
        
        CGPathRef   boundingPath = [layer newOutlinePathWhileUsingRadialGradient:self.control.useRadialGradient];
        CGContextAddPath(quartzContext, boundingPath);
        CGGradientRef   gradientToUse = 0;
        if(layer.selected)
        {
            gradientToUse = self.control.faceGradientSelected;
        }
        else if(layer.isHighlighted)
        {
            gradientToUse = self.control.faceGradientPressed;
        }
        else
        {
            gradientToUse = self.control.faceGradient;
        }
        
        NSAssert((gradientToUse != 0), @"GHControl: Not setup properly");
        
        // draw subtly gradiented interior
        CGRect interiorRect = self.control.useRadialGradient?layerBounds:CGRectInset(layerBounds, kRingThickness, kRingThickness);
        
        if(self.control.showShadow)
        {
            drawRing = NO;
        }
        
        
        CGContextClip(quartzContext);
        
        CGPoint topPoint = layerBounds.origin;
        CGPoint bottomPoint = CGPointMake(layerBounds.origin.x, layerBounds.origin.y+layerBounds.size.height);
        if(self.control.useRadialGradient)
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
            CGPathRef interiorRingPath = [layer newInteriorRingPahtWhileUsingRadialGradient:self.control.useRadialGradient];
            CGContextSetLineWidth(quartzContext, 1/self.contentsScale);
            if(inNormalMode)
            {
                CGContextSetStrokeColorWithColor(quartzContext, [[UIColor darkGrayColor] colorWithAlphaComponent:0.5].CGColor);
            }
            else
            {
                CGContextSetStrokeColorWithColor(quartzContext, self.control.ringColor.CGColor);
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
            CGPathRef exteriorRingPath = [layer newExteriorRingPath];
            CGContextSetLineWidth(quartzContext, 1/self.contentsScale);
            CGContextSetStrokeColorWithColor(quartzContext, self.control.ringColor.CGColor);
            
            CGContextAddPath(quartzContext, exteriorRingPath);
            CGContextStrokePath(quartzContext);
            CGPathRelease(exteriorRingPath);
        }
    }
    
    CGContextRestoreGState(quartzContext);
}

@end


@implementation GHSegmentedControl

+(void)makeSureLoaded
{
}

+(Class) layerClass
{
    return [GHSegmentedControlLayer class];
}

-(GHSegmentedControlLayer*)layerAsControlLayer
{
    GHSegmentedControlLayer* result =  (GHSegmentedControlLayer*)self.layer;
    result.control = self;
    return result;
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
            [self.layerAsControlLayer insertDefinition:newDefinition atIndex:segment animated:animated];
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
            [self.layerAsControlLayer insertDefinition:newDefinition atIndex:segment animated:animated];
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
            [self.layerAsControlLayer removeSegmentAtIndex:segment animated:YES];
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
        [self.layerAsControlLayer updateSegmentAtIndex:segment withDefinition:definition];
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
        [self.layerAsControlLayer updateSegmentAtIndex:segment withDefinition:definition];
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
        [self.layerAsControlLayer updateSegmentAtIndex:segment withDefinition:definition];
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
        [self.layerAsControlLayer updateSegmentAtIndex:segment withDefinition:definition];
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
        [self.layerAsControlLayer updateSegmentAtIndex:segment withDefinition:definition];
        
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


- (void)drawRect:(CGRect)rect {
}

- (CGSize)intrinsicContentSize
{
    UIFont* font = [GHSegmentedControlLayer titleFontForState:UIControlStateNormal];
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

-(void) setDefinitions:(NSArray *)definitions
{
    _definitions = definitions;
    self.layerAsControlLayer.definitions = definitions;
    if([self respondsToSelector:@selector(invalidateIntrinsicContentSize)])
    {
        [self invalidateIntrinsicContentSize];
    }
}

-(void) setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    _selectedSegmentIndex = selectedSegmentIndex;
    self.layerAsControlLayer.selectedSegmentIndex = selectedSegmentIndex;
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
    NSInteger result = [self.layerAsControlLayer indexOfTouch:touchLocation];
    return result;
}


-(void) updateTracking:(UITouch*)touch
{
    CGPoint localPoint = [touch locationInView:self];
    NSInteger hitSegment = [self.layerAsControlLayer indexOfTouch:localPoint];
    
    if(self.layerAsControlLayer.trackedSegmentIndex != hitSegment)
    {
        self.layerAsControlLayer.trackedSegmentIndex = hitSegment;
    }
}

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
    NSInteger trackedSegmentIndex = self.layerAsControlLayer.trackedSegmentIndex;
    if(trackedSegmentIndex == NSNotFound)
    {
    }
    else if(trackedSegmentIndex != self.layerAsControlLayer.selectedSegmentIndex)
    {
        self.selectedSegmentIndex = trackedSegmentIndex;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    self.layerAsControlLayer.trackedSegmentIndex = NSNotFound;
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    self.layerAsControlLayer.trackedSegmentIndex = NSNotFound;
    [super cancelTrackingWithEvent:event];
}

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
        CGRect localFrame = [self.layerAsControlLayer frameForSegmentAtIndex:index];
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
    }
}

- (void)accessibilityDecrement
{
    if(self.selectedSegmentIndex > 0 && self.definitions.count > 0)
    {
        [self setSelectedSegmentIndex:self.selectedSegmentIndex-1];
    }
}


@end

@implementation GHSegmentedControlAccessibilityWrapper


-(CGRect) accessibilityFrame
{
    CGRect result = [super accessibilityFrame];
    if([self.accessibilityContainer isKindOfClass:[GHSegmentedControl class]])
    {
        GHSegmentedControl* myControl = self.accessibilityContainer;
        CGRect localFrame = [myControl.layerAsControlLayer frameForSegmentAtIndex:self.index];
        result = UIAccessibilityConvertFrameToScreenCoordinates(localFrame, myControl);;
    }
    
    return result;
}
@end
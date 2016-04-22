//
//  SVGAttributedObject.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2014 Glenn R. Howes

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

//
//  Created by Glenn Howes on 1/25/14.
//

#import "SVGAttributedObject.h"
#import "SVGRenderer.h"
#import "GHGradient.h"
#import "SVGPathGenerator.h"
#import "GHText.h"
#import "SVGTextUtilities.h"

@interface GHAttributedObject(SVGRenderer)

+(NSDictionary*) overideObjectsForPrototype:(id)prototype withDictionary:(NSDictionary*)deltaDictionary;
-(instancetype) cloneWithOverridingDictionary:(NSDictionary*)overrideAttributes;
@end

@interface GHRenderableObject()
{
@private
    CGAffineTransform	transform;
}
@end

@implementation GHAttributedObject(SVGRenderer)
+(NSDictionary*) overideObjectsForPrototype:(id)prototype withDictionary:(NSDictionary*)deltaDictionary
{
    NSDictionary* result = nil;
    if([prototype respondsToSelector:@selector(attributes)])
    {
        NSDictionary* oldAttributes = (NSDictionary*)[prototype attributes];
        NSMutableDictionary* newAttributesMutable = [[NSMutableDictionary alloc] initWithCapacity:[deltaDictionary count]+[oldAttributes count]];
        NSString* oldXLink = [oldAttributes objectForKey:@"xlink:href"];
        if([oldAttributes count])
        {
            [newAttributesMutable addEntriesFromDictionary:oldAttributes];
        }
        
        [newAttributesMutable addEntriesFromDictionary:deltaDictionary];
        if(oldXLink)
        {
            [newAttributesMutable setObject:oldXLink forKey:@"xlink:href"];// don't override xlink:href
        }
        if([prototype respondsToSelector:@selector(transform)])
        {
            NSString*	transformAttribute = [deltaDictionary objectForKey:@"transform"];
            CGAffineTransform   oldTransform = [(id<GHRenderable>)prototype transform];
            CGAffineTransform   additionalTransform = SVGTransformToCGAffineTransform(transformAttribute);
            
            if(!CGAffineTransformIsIdentity(additionalTransform)) // we have to apply the transform to the old one
            {
                if(CGAffineTransformIsIdentity(oldTransform))
                {// old one was identity, so might as well just use the new string
                    [newAttributesMutable setValue:transformAttribute forKey:@"transform"];
                }
                else
                {
                    CGAffineTransform newTransform = CGAffineTransformConcat(oldTransform,
                                                                             additionalTransform);
                    NSString* newSVGTransform = CGAffineTransformToSVGTransform(newTransform);
                    [newAttributesMutable setValue:newSVGTransform forKey:@"transform"];
                }
            }
        }
        NSString* oldStyleString = [oldAttributes objectForKey:@"style"];
        NSString* newStyleString = [deltaDictionary objectForKey:@"style"];
        
        if([oldStyleString length] && [newStyleString length])
        { // we have to merge the style attributes
            NSDictionary* newStyles =  [SVGToQuartz dictionaryForStyleAttributeString:newStyleString];
            NSDictionary* oldStyles = [SVGToQuartz dictionaryForStyleAttributeString:oldStyleString];
            NSMutableDictionary* combinedStyles = [NSMutableDictionary dictionaryWithDictionary:oldStyles];
            [combinedStyles addEntriesFromDictionary:newStyles];
            NSString* combinedStyleString = [SVGToQuartz styleAttributeStringForDictionary:combinedStyles];
            
            [newAttributesMutable setValue:combinedStyleString forKey:@"style"];
        }
        else if([newStyleString length])
        {
            [newAttributesMutable setValue:newStyleString forKey:@"style"];
        }
        
        result = [NSDictionary dictionaryWithObject:[newAttributesMutable copy] forKey:kAttributesElementName];
    }
    
    return result;
}


-(id) cloneWithOverridingDictionary:(NSDictionary*)overrideAttributes
{
    NSDictionary* newDefinition = [GHAttributedObject overideObjectsForPrototype:self withDictionary:overrideAttributes];
    id result = [[[self class] alloc] initWithDictionary:newDefinition];
    
    return result;
}

@end

@implementation GHRenderableObject
@synthesize transform, fillColor=_fillColor;

+(void) setupContext:(CGContextRef)quartzContext withAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext
{
    NSString*	strokeString = [SVGToQuartz valueForStyleAttribute:@"stroke-width" fromDefinition:attributes];
    NSString* vectorEffect = [SVGToQuartz valueForStyleAttribute:@"vector-effect" fromDefinition:attributes];
    
    [SVGToQuartz setupLineWidthForQuartzContext:quartzContext withSVGStrokeString:strokeString withVectorEffect:vectorEffect withSVGContext:svgContext];
    
    NSString*	miterLimitString = [SVGToQuartz valueForStyleAttribute:@"stroke-miterlimit" fromDefinition:attributes];
    [SVGToQuartz setupMiterLimitForQuartzContext:quartzContext withSVGMiterLimitString:miterLimitString];
    
    NSString*	lineJoinString = [SVGToQuartz valueForStyleAttribute:@"stroke-linejoin" fromDefinition:attributes];
    [SVGToQuartz setupMiterForQuartzContext:quartzContext withSVGMiterString:lineJoinString];
    
    
    NSString*	lineCapString = [SVGToQuartz valueForStyleAttribute:@"stroke-linecap" fromDefinition:attributes];
    [SVGToQuartz setupLineEndForQuartzContext:quartzContext withSVGLineEndString:lineCapString];
    
    NSString*	strokeDashString = [[SVGToQuartz valueForStyleAttribute:@"stroke-dasharray" fromDefinition:attributes]
                                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString*	phaseString = [SVGToQuartz valueForStyleAttribute:@"stroke-dashoffset" fromDefinition:attributes];
    [SVGToQuartz setupLineDashForQuartzContext:quartzContext withSVGDashArray:(NSString*)strokeDashString andPhase:phaseString];
    
    NSString* colorString = [attributes objectForKey:@"color"];
    [SVGToQuartz setupColorForQuartzContext:quartzContext withColorString:colorString withSVGContext:svgContext];
    
    NSString* opacityString = [attributes objectForKey:@"opacity"];
    [SVGToQuartz setupOpacityForQuartzContext:quartzContext withSVGOpacity:opacityString];
}


+(CGRect) boundingBoxForRenderableObject:(id<GHRenderable>)anObject withSVGContext:(id<SVGContext>) svgContext givenParentObjectsBounds:(CGRect)parentBounds
{
    CGRect result = [anObject getBoundingBoxWithSVGContext:svgContext];
    if(!CGRectIsEmpty(parentBounds))
    {
        if([[[anObject attributes] objectForKey:@"clipPathUnits"] isEqualToString:@"objectBoundingBox"]
           || [[[anObject attributes] objectForKey:@"maskContentUnits"] isEqualToString:@"objectBoundingBox"])
        {
            CGAffineTransform mappingTransform = CGAffineTransformMakeTranslation(parentBounds.origin.x,
                                                                                  parentBounds.origin.y);
            mappingTransform = CGAffineTransformScale(mappingTransform, parentBounds.size.width, parentBounds.size.height);
            result = CGRectApplyAffineTransform(result, mappingTransform);
        }
    }
    return result;
}

-(void) setupContext:(CGContextRef)quartzContext withAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext
{
    id newDefaultColor = [attributes objectForKey:@"color"];
    if([newDefaultColor isKindOfClass:[NSString class]])
    {
        UIColor* newCurrentColor = [svgContext colorForSVGColorString:newDefaultColor];
        if(newCurrentColor)
        {
            [svgContext setCurrentColor:newCurrentColor];
        }
    }
    [GHRenderableObject setupContext:quartzContext withAttributes:attributes withSVGContext:svgContext];
    id clippingObject = [GHClipGroup clipObjectForAttributes:attributes withSVGContext:svgContext];
    if(clippingObject != nil)
    {
        CGRect myBoundingBox = [self getBoundingBoxWithSVGContext:svgContext];
        [clippingObject addToClipForContext:quartzContext  withSVGContext:svgContext objectBoundingBox:myBoundingBox];
    }
}

-(BOOL) hidden
{
    BOOL result = [SVGToQuartz attributeHasDisplaySetToNone:self.attributes];
    return result;
}

-(NSString*) description
{
    NSString* result = [self.attributes description];
    return result;
}

-(void) addNamedObjects:(NSMutableDictionary*)namedObjectsMap
{
    NSString* myName = [self.attributes objectForKey:@"id"];
    if([myName isKindOfClass:[NSString class]] && [myName length])
    {
        [namedObjectsMap  setValue:self forKey:myName];
    }
    else
    {
        myName = [self.attributes objectForKey:@"xml:id"];
        if([myName isKindOfClass:[NSString class]] && [myName length])
        {
            [namedObjectsMap  setValue:self forKey:myName];
        }
    }
}

-(NSString*) valueForStyleAttribute:(NSString*)attributeName   withSVGContext:(id<SVGContext>)svgContext
{
    NSString* result = [SVGToQuartz valueForStyleAttribute:attributeName fromDefinition:self.attributes];
    return result;
}

-(NSString*) defaultFillColor
{
    NSString* result = [self valueForStyleAttribute:@"fill" withSVGContext:nil];
    if([result length] == 0)
    {
        result = kBlackInHex;
    }
    return result;
}

-(id) initWithDictionary:(NSDictionary*)theDefinition
{
    if(nil != (self = [super initWithDictionary:theDefinition]))
    {
        NSString*	transformAttribute = [self.attributes objectForKey:@"transform"];
        transform = SVGTransformToCGAffineTransform(transformAttribute);
    }
    return self;
}


-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{// base class has no mechanism for rendering, subclasses handle this.
}


-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{// base class doesn't know how to do this.
    
}

-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    
}


-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{// base class doesn't know how to do this.
    ClippingType result = kNoClippingType;
    return result;
}
-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{// base class doesn't know how to do this.
    CGRect result = CGRectZero;
    return result;
}

-(BOOL)	hitTest:(CGPoint) testPoint
{
    BOOL	result = NO;
    return result;
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint withSVGContext:(id<SVGContext>)svgContext
{
    id<GHRenderable> result = nil;
    if([self hitTest:testPoint])
    {
        result = self;
    }
    return result;
}

@end


@interface SVGDocumentImage : GHRenderableObject
{
    SVGRenderer* renderer;
    BOOL        loaded;
}
@end

@implementation SVGDocumentImage

-(SVGRenderer*) rendererForSVGContext:(id<SVGContext>)svgContext
{
    SVGRenderer* result = renderer;
    if(result == nil && !loaded)
    {
        loaded = YES;
        NSString* reference = [self.attributes objectForKey:@"xlink:href"];
        NSString* basePath = [self.attributes objectForKey:@"xml:base"];
        if([basePath length])
        {
            reference = [basePath stringByAppendingPathComponent:reference];
        }
        NSURL*	referenceURL = [svgContext relativeURL:reference];
        result = renderer = [[SVGRenderer alloc] initWithContentsOfURL:referenceURL];
    }
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    [myRenderer renderIntoContext:quartzContext withSVGContext:svgContext];
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint withSVGContext:(id<SVGContext>)svgContext
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    id<GHRenderable> result = [myRenderer findRenderableObject:testPoint withSVGContext:svgContext];
    return result;
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    [myRenderer addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}

-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    [myRenderer addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    ClippingType result = [myRenderer getClippingTypeWithSVGContext:svgContext];
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    SVGRenderer* myRenderer = [self rendererForSVGContext:svgContext];
    CGRect result = [myRenderer getBoundingBoxWithSVGContext:svgContext];
    return result;
}
@end


@implementation GHImage


+(id<GHRenderable>)newImageWithDictionary:(NSDictionary*)aDefinition
{
    id result = nil;
    NSDictionary* attributes  = [aDefinition objectForKey:kAttributesElementName];
    NSString* reference = [attributes objectForKey:@"xlink:href"];
    if([reference hasSuffix:@".svg"])
    {
        result = [[SVGDocumentImage alloc] initWithDictionary:aDefinition];
    }
    else
    {
        result = [[GHImage alloc] initWithDictionary:aDefinition];
    }
    
    return result;
}

-(CGRect) boundsBox
{
    CGFloat	xLocation = [[self.attributes objectForKey:@"x"] floatValue];
    CGFloat yLocation = [[self.attributes objectForKey:@"y"] floatValue];
    CGFloat width = [[self.attributes objectForKey:@"width"] floatValue];
    CGFloat height = [[self.attributes objectForKey:@"height"] floatValue];
    
    CGRect result = CGRectMake(xLocation, yLocation, width, height);
    return result;
}
-(NSString*) entityName
{
    return @"image";
}


-(UIImage*) newNativeImageWithSVGContext:(id<SVGContext>)svgContext
{
    __block UIImage* result = nil;
    NSString* subPath = [self.attributes objectForKey:@"xlink:href"];
    NSString* basePath = [self.attributes objectForKey:@"xml:base"];
    
    [SVGToQuartz imageAtXLinkPath:subPath orAtRelativeFilePath:basePath withSVGContext:svgContext
                     intoCallback:^(UIImage *anImage, NSURL *location) {
                         result = anImage;
                     }];
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = [self boundsBox];
    return result;
}

-(BOOL)	hitTest:(CGPoint) testPoint
{
    BOOL	result = NO;
    CGRect myRect = [self boundsBox];
    
    CGAffineTransform invertedTransform = CGAffineTransformInvert(self.transform);
    
    testPoint = CGPointApplyAffineTransform(testPoint,invertedTransform);
    
    if(CGRectContainsPoint(myRect, testPoint))
    {
        result = YES;
    }
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    CGRect myRect = [self boundsBox];
    NSString* subPath = [self.attributes objectForKey:@"xlink:href"];
    if([subPath length] && !CGRectIsEmpty(myRect))
    {
        UIImage* myImage = [self newNativeImageWithSVGContext:svgContext];
        if(myImage != nil && myImage.CGImage != 0)
        {
            CGContextSaveGState(quartzContext);
            CGContextConcatCTM(quartzContext, self.transform);
            CGContextTranslateCTM(quartzContext, myRect.origin.x, myRect.origin.y);
            
            id clippingObject = [GHClipGroup clipObjectForAttributes:self.attributes withSVGContext:svgContext];
            if(clippingObject)
            {
                [clippingObject addToClipForContext:quartzContext  withSVGContext:svgContext objectBoundingBox:CGRectZero];
            }
            
            myRect.origin.x = 0.0;
            myRect.origin.y = 0.0;
            CGContextTranslateCTM(quartzContext, 0, myRect.size.height); // now flip the context upside down to render the image.
            CGContextScaleCTM(quartzContext, 1.0, -1);
            
            CGImageRef   quartzImage =  myImage.CGImage;
            if(quartzImage != 0)
            {
                NSString*	viewPortColorString = [self.attributes objectForKey:@"viewport-fill"];
                if(viewPortColorString != nil && ![viewPortColorString isEqualToString:@"none"]
                   && ![viewPortColorString isEqualToString:@"inherit"])
                {
                    if(![viewPortColorString isEqualToString:@"currentColor"])
                    {
                        UIColor* aColor = [svgContext colorForSVGColorString:viewPortColorString];
                        if(aColor.CGColor != 0)
                        {
                            CGContextSetFillColorWithColor(quartzContext, aColor.CGColor);
                            CGContextAddRect(quartzContext, myRect);
                            CGContextFillPath(quartzContext);
                        }
                    }
                }
                
                CGRect	drawRect = myRect;
                NSString* preserveAspectRatioString = [self.attributes objectForKey:@"preserveAspectRatio"];
                if(preserveAspectRatioString != nil && ![preserveAspectRatioString isEqualToString:@"none"])
                {
                    CGFloat	naturalWidth = CGImageGetWidth(quartzImage);
                    CGFloat	naturalHeight = CGImageGetHeight(quartzImage);
                    CGSize	naturalSize = CGSizeMake(naturalWidth, naturalHeight);
                    drawRect = [SVGToQuartz aspectRatioDrawRectFromString:preserveAspectRatioString givenBounds:drawRect naturalSize:naturalSize];
                    if(drawRect.size.width > myRect.size.width || drawRect.size.height > myRect.size.height)
                    {
                        CGContextClipToRect(quartzContext, myRect);
                    }
                }
                if(!CGRectIsEmpty(drawRect))
                {
                    
                    NSString*   opacityString = [self.attributes objectForKey:@"opacity"];
                    CGFloat     alpha = 1.0;
                    if(opacityString.length)
                    {
                        if([opacityString isEqualToString:@"none"] || [opacityString isEqualToString:@"inherit"])
                        {
                        }
                        else
                        {
                            alpha = [opacityString floatValue];
                            CGContextSetAlpha(quartzContext, alpha);
                        }
                    }
                    CGContextDrawImage(quartzContext, drawRect, quartzImage);
                }
            }
            CGContextRestoreGState(quartzContext);
        }
    }
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    CGRect myRect = [self boundsBox];
    NSString* subPath = [self.attributes objectForKey:@"xlink:href"];
    if([subPath length] && !CGRectIsEmpty(myRect))
    {
        UIImage* myImage = [self newNativeImageWithSVGContext:svgContext];
        if(myImage != nil && myImage.CGImage != 0)
        {
            CGAffineTransform oldTransform = CGContextGetCTM(quartzContext);
            CGContextConcatCTM(quartzContext, self.transform);
            CGContextTranslateCTM(quartzContext, myRect.origin.x, myRect.origin.y);
            myRect.origin.x = 0.0;
            myRect.origin.y = 0.0;
            CGContextTranslateCTM(quartzContext, 0, myRect.size.height);
            CGContextScaleCTM(quartzContext, 1.0, -1);
            
            CGImageRef   quartzImage =  myImage.CGImage;
            
            CGRect	drawRect = myRect;
            NSString* preserveAspectRatioString = [self.attributes objectForKey:@"preserveAspectRatio"];
            if(preserveAspectRatioString != nil && ![preserveAspectRatioString isEqualToString:@"none"])
            {
                CGFloat	naturalWidth = CGImageGetWidth(quartzImage);
                CGFloat	naturalHeight = CGImageGetHeight(quartzImage);
                CGSize	naturalSize = CGSizeMake(naturalWidth, naturalHeight);
                drawRect = [SVGToQuartz aspectRatioDrawRectFromString:preserveAspectRatioString givenBounds:drawRect naturalSize:naturalSize];
            }
            if(!CGRectIsEmpty(drawRect))
            {
                CGContextClipToMask(quartzContext, drawRect, quartzImage);
            }
            
            
            CGAffineTransform modifiedTransform = CGContextGetCTM(quartzContext);
            
            CGAffineTransform invertedModifiedTransform = CGAffineTransformInvert(modifiedTransform);
            CGContextConcatCTM(quartzContext, invertedModifiedTransform); // set the context's transform back to 1 1 1 0 0
            CGContextConcatCTM(quartzContext, oldTransform); // set the tranform back to where I started. not using CGContextRestoreGState because it would undo my clipping
            
        }
    }
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kImageClipplingType;
    return result;
}


@end

@interface GHShape(Private)
-(CGPathRef) newQuartzPath;
-(void) setupContext:(CGContextRef)quartzContext withAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext;
-(BOOL) addPathToQuartzContext:(CGContextRef) quartzContext;
@end

@implementation GHShape(Private)

-(CGPathRef) newQuartzPath
{
    return 0;
}

-(void) setupContext:(CGContextRef)quartzContext withAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext
{
    [super	setupContext:quartzContext withAttributes:self.attributes withSVGContext:svgContext];
}

-(BOOL) addPathToQuartzContext:(CGContextRef) quartzContext
{
    CGPathRef	myPath  = self.quartzPath;
    BOOL result = myPath != 0;
    if(result)
    {
        CGContextAddPath(quartzContext, myPath);
    }
    return result;
    
}


@end

@implementation GHShape
@synthesize	isClosed, isFillable,  quartzPath=_quartzPath;
-(CGPathRef) quartzPath
{
    if(_quartzPath == 0)
    {
        _quartzPath = [self newQuartzPath];
    }
    return _quartzPath;
}


-(BOOL) isClosed
{
    BOOL	result = NO;
    return result;
}

-(BOOL) isFillable
{
    BOOL result = NO;
    return result;
}

-(BOOL)	hitTest:(CGPoint) testPoint
{
    BOOL	result = NO;
    
    if(self.isFillable)
    {
        CGPathRef	myPath  = self.quartzPath;
        
        CGAffineTransform invertedTransform = CGAffineTransformInvert(self.transform);
        if(CGPathContainsPoint(myPath, &invertedTransform, testPoint, false))
        {
            result = YES;
        }
    }
    
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = CGRectZero;
    CGPathRef basePath = self.quartzPath;
    if(basePath)
    {
        if(CGAffineTransformIsIdentity(self.transform))
        {
            result =  CGPathGetPathBoundingBox(basePath);
        }
        else
        {
            CGAffineTransform myTransform = self.transform;
            CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(basePath, &myTransform);
            result = CGPathGetPathBoundingBox(transformedPath);
            CGPathRelease(transformedPath);
        }
    }
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext
{
    CGContextSaveGState(quartzContext);
    CGContextConcatCTM(quartzContext, self.transform);
    [self setupContext:quartzContext withAttributes:self.attributes withSVGContext:svgContext];
    UIColor* strokeColorUI = nil;
    NSString* strokeColorString = [self valueForStyleAttribute:@"stroke" withSVGContext:svgContext];
    
    GHGradient* gradientToStroke = nil;
    
    if(IsStringURL(strokeColorString))
    {
        id aColor = [svgContext objectAtURL:strokeColorString];
        if([aColor isKindOfClass:[GHSolidColor class]])
        {
            strokeColorUI = [aColor asColorWithSVGContext:svgContext];
        }
        else if([aColor isKindOfClass:[GHGradient class]])
        {
            gradientToStroke = aColor;
        }
    }
    
    NSString* fillString = [self valueForStyleAttribute:@"fill" withSVGContext:svgContext];
    CGPathDrawingMode drawingMode = kCGPathStroke;
    
    
    NSString* fillRuleString = [self valueForStyleAttribute:@"fill-rule" withSVGContext:svgContext];
    BOOL	evenOddFill = [fillRuleString isEqualToString:@"evenodd"];
    if(!evenOddFill)
    {// we might be in a clip path
        fillRuleString = [self valueForStyleAttribute:@"clip-rule" withSVGContext:svgContext];
        evenOddFill = [fillRuleString isEqualToString:@"evenodd"];
    }
    
    
    NSString* fillOpacityString = [self valueForStyleAttribute:@"fill-opacity" withSVGContext:svgContext];
    CGFloat	fillOpacity = 1.0;
    if([fillOpacityString length])
    {
        fillOpacity = [fillOpacityString floatValue];
        if(fillOpacity < 0.0) fillOpacity = 0.0;
        if(fillOpacity > 1.0) fillOpacity = 1.0;
    }
    NSString* strokeOpacityString = [self valueForStyleAttribute:@"stroke-opacity" withSVGContext:svgContext];
    CGFloat strokeOpacity = 1.0;
    
    if([strokeOpacityString length])
    {
        strokeOpacity = [strokeOpacityString floatValue];
        if(strokeOpacity < 0.0) strokeOpacity = 0.0;
        if(strokeOpacity > 1.0) strokeOpacity = 1.0;
    }
    
    BOOL	fillIt = (fillOpacity > 0.0 && ![fillString isEqualToString:@"none"]);
    
    if(fillIt && self.isFillable)
    {
    }
    else if(fillIt)
    {
        fillIt = fillString.length > 0;
    }


    BOOL strokeIt = (strokeOpacity > 0.0 && (strokeColorString != nil && ![strokeColorString isEqualToString:@"none"]));
    
    GHGradient* gradientToFill = nil;
    if(fillIt)
    {
        UIColor* colorToFill = self.fillColor;
        
        if(colorToFill == nil)
        {
            NSString*	colorToUse = [self defaultFillColor];
            if(IsStringURL(fillString))
            {
                id aColor = [svgContext objectAtURL:fillString];
                if([aColor isKindOfClass:[GHSolidColor class]])
                {
                    colorToFill = [aColor asColorWithSVGContext:svgContext];
                }
                else if([aColor isKindOfClass:[GHGradient class]])
                {
                    gradientToFill = aColor;
                }
                
            }
            if(colorToFill == nil && colorToUse != nil)
            {
                colorToFill = [svgContext colorForSVGColorString:colorToUse];
            }
            if(![fillString isEqualToString:@"currentColor"] && ![fillString isEqualToString:@"inherit"])
            {
                self.fillColor = colorToFill;
            }
            
        }
        if(fillOpacity != 1.0)
        {
            colorToFill = [colorToFill colorWithAlphaComponent:fillOpacity];
        }
        if(colorToFill != nil)
        {
            CGContextSetFillColorWithColor(quartzContext, colorToFill.CGColor);
        }
        if(evenOddFill)
        {
            drawingMode = strokeIt?kCGPathEOFillStroke:kCGPathEOFill;
        }
        else
        {
            drawingMode = strokeIt?kCGPathFillStroke:kCGPathFill;
        }
    }
    if(strokeIt)
    {
        NSString* strokeColor = [self valueForStyleAttribute:@"stroke" withSVGContext:svgContext];
        if(strokeColorUI == nil && strokeColor != nil)
        {
            strokeColorUI = [svgContext colorForSVGColorString:strokeColor];
        }
        if(strokeColorUI != nil)
        {
            if(strokeOpacity < 1.0)
            {
                strokeColorUI = [strokeColorUI colorWithAlphaComponent:strokeOpacity];
            }
            CGContextSetStrokeColorWithColor(quartzContext, strokeColorUI.CGColor);
        }
    }
    
    if(gradientToFill != nil)
    {
        CGContextSaveGState(quartzContext);
        if([self addPathToQuartzContext:quartzContext])
        {
            CGContextRestoreGState(quartzContext);
            CGRect myBox  =  CGPathGetPathBoundingBox(self.quartzPath);
            
            if(fillOpacity < 1.0)
            {
                CGContextSaveGState(quartzContext);
                CGContextSetAlpha(quartzContext, fillOpacity);
            }
            if(!CGRectIsEmpty(myBox))
            {
                [gradientToFill fillPathToContext:quartzContext withSVGContext:svgContext objectBoundingBox:myBox];
            }
            if(fillOpacity < 1.0)
            {
                CGContextRestoreGState(quartzContext);
            }
        }
        if(strokeIt)
        {
            drawingMode = kCGPathStroke;
        }
        fillIt = false;
    }
    if(gradientToStroke)
    {
        if([self addPathToQuartzContext:quartzContext])
        {
            CGContextReplacePathWithStrokedPath(quartzContext);
            CGRect myBox  =  CGPathGetPathBoundingBox(self.quartzPath);
            myBox = CGRectApplyAffineTransform(myBox, self.transform);
            if(!CGRectIsEmpty(myBox))
            {
                [gradientToStroke fillPathToContext:quartzContext withSVGContext:svgContext objectBoundingBox:myBox];
            }
        }
        strokeIt = false;
        if(fillIt)
        {
            if([self addPathToQuartzContext:quartzContext])
            {
                switch(drawingMode)
                {
                    case kCGPathFillStroke:
                        drawingMode = kCGPathFill;
                        break;
                    case kCGPathEOFillStroke:
                        drawingMode = kCGPathEOFill;
                        break;
                    default:
                    {
                    }
                        break;
                }
            }
            else
            {
                fillIt = strokeIt = false;
            }
        }
    }
    
    if(fillIt || strokeIt)
    {
        if ([self addPathToQuartzContext:quartzContext])
        {
            CGContextDrawPath(quartzContext, drawingMode);
        }
        
    }
    CGContextRestoreGState(quartzContext);
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    CGContextSaveGState(quartzContext);
    CGContextConcatCTM(quartzContext, self.transform);
    [self addPathToQuartzContext:quartzContext];
    CGContextRestoreGState(quartzContext);
    NSString* fillRuleString = [self valueForStyleAttribute:@"clip-rule" withSVGContext:svgContext];
    BOOL	evenOddFill = [fillRuleString isEqualToString:@"evenodd"];
    if(evenOddFill)
    {
        CGContextEOClip(quartzContext);
    }
    else
    {
        CGContextClip(quartzContext);
    }
}

-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    [super addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
    CGContextSaveGState(quartzContext);
    CGContextConcatCTM(quartzContext, self.transform);
    [self addPathToQuartzContext:quartzContext];
    CGContextRestoreGState(quartzContext);
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kPathClippingType;
    
    NSString* fillRuleString = [self valueForStyleAttribute:@"clip-rule" withSVGContext:svgContext];
    BOOL	evenOddFill = [fillRuleString isEqualToString:@"evenodd"];
    if(evenOddFill)
    {
        result = kEvenOddPathClippingType;
    }
    return result;
}

-(void) dealloc
{
    CGPathRelease(_quartzPath);
}

@end

@implementation GHCircle
-(CGPathRef) newQuartzPath
{
    CGMutablePathRef	mutableResult = CGPathCreateMutable();
    CGFloat		centerX = [[self.attributes objectForKey:@"cx"] floatValue];
    CGFloat		centerY = [[self.attributes objectForKey:@"cy"] floatValue];
    CGFloat		radiusX = [[self.attributes objectForKey:@"r"] floatValue];
    CGFloat		radiusY = radiusX;
    
    CGRect		ellipseBox = CGRectMake(centerX-radiusX, centerY-radiusY, 2.0f*radiusX, 2.0f*radiusY);
    CGPathAddEllipseInRect(mutableResult, NULL, ellipseBox);
    
    CGPathRef result = CGPathCreateCopy(mutableResult);
    CGPathRelease(mutableResult);
    return result;
}

-(NSString*) entityName
{
    return @"circle";
}


@end

@implementation GHLine

-(BOOL) isClosed
{
    BOOL	result = NO;
    return result;
}

-(NSString*) entityName
{
    return @"line";
}


-(BOOL) isFillable
{
    BOOL result = NO;
    return result;
}

-(CGPathRef) newQuartzPath
{
    CGMutablePathRef	mutableResult = CGPathCreateMutable();
    CGFloat		startX = [[self.attributes objectForKey:@"x1"] floatValue];
    CGFloat		startY = [[self.attributes objectForKey:@"y1"] floatValue];
    CGFloat		endX = [[self.attributes objectForKey:@"x2"] floatValue];
    CGFloat		endY = [[self.attributes objectForKey:@"y2"] floatValue];
    
    
    CGPathMoveToPoint(mutableResult, NULL, startX, startY);
    CGPathAddLineToPoint(mutableResult, NULL, endX, endY);
    
    CGPathRef result = CGPathCreateCopy(mutableResult);
    CGPathRelease(mutableResult);
    return result;
}

@end

@implementation GHPolyline

-(BOOL) isClosed
{
    BOOL	result = NO;
    return result;
}


-(BOOL) isFillable
{
    BOOL result = YES;
    return result;
}

-(NSString*) entityName
{
    return @"polyline";
}


-(NSString*) renderingPath // Path will take our points and treat them like a M operation followed by a series of implied Line tos
{
    NSString* result = [self.attributes objectForKey:@"points"];
    NSArray* testComponent = [result componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
    
    NSMutableArray* mutableTestComponent = [testComponent mutableCopy];
    [mutableTestComponent removeObject:@""];// what if there was both a space and a ,
    if(mutableTestComponent.count != testComponent.count)
    { // got some blank spaces
        testComponent = mutableTestComponent;
        result = [mutableTestComponent componentsJoinedByString:@","];
    }
    
    if([testComponent count] & 1)
    {
        result = nil;
    }
    return result;
}
@end

@implementation GHPolygon

-(BOOL) isClosed
{
    BOOL	result = YES;
    return result;
}

-(NSString*) entityName
{
    return @"polygon";
}


-(BOOL) isFillable
{
    BOOL result = YES;
    return result;
}

-(NSString*) renderingPath // Path will take our points and treat them like a M operation followed by a series of implied Line tos
{		// followed by a close
    NSString* result = [self.attributes objectForKey:@"points"];
    NSArray* testComponent = [result componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
    NSMutableArray* mutableTestComponent = [testComponent mutableCopy];
    [mutableTestComponent removeObject:@""];// what if there was both a space and a ,
    if(mutableTestComponent.count != testComponent.count)
    { // got some blank spaces
        testComponent = mutableTestComponent;
        result = [mutableTestComponent componentsJoinedByString:@","];
    }
    if([testComponent count] & 1)
    {// need an even number of x, y values
        result = nil;
    }
    result = [result stringByAppendingString:@" z"];
    return result;
}

@end

@implementation GHEllipse

-(BOOL) isClosed
{
    BOOL	result = YES;
    return result;
}

-(NSString*) entityName
{
    return @"ellipse";
}


-(BOOL) isFillable
{
    BOOL result = YES;
    return result;
}

-(CGPathRef) newQuartzPath
{
    CGPathRef result = 0;
    CGFloat		centerX = [[self.attributes objectForKey:@"cx"] floatValue];
    CGFloat		centerY = [[self.attributes objectForKey:@"cy"] floatValue];
    CGFloat		radiusX = [[self.attributes objectForKey:@"rx"] floatValue];
    CGFloat		radiusY = [[self.attributes objectForKey:@"ry"] floatValue];
    
    CGRect		ellipseBox = CGRectMake(centerX-radiusX, centerY-radiusY, 2.0f*radiusX, 2.0f*radiusY);
    if(!CGRectIsEmpty(ellipseBox))
    {
        
        CGMutablePathRef	mutableResult = CGPathCreateMutable();
        CGPathAddEllipseInRect(mutableResult, NULL, ellipseBox);
        
        result = CGPathCreateCopy(mutableResult);
        CGPathRelease(mutableResult);
    }
    return result;
}

@end

@implementation GHRectangle

-(CGRect) asCGRect
{
    CGFloat		originX = [[self.attributes objectForKey:@"x"] floatValue];
    CGFloat		originY = [[self.attributes objectForKey:@"y"] floatValue];
    CGFloat		width = [[self.attributes objectForKey:@"width"] floatValue];
    CGFloat		height = [[self.attributes objectForKey:@"height"] floatValue];
    
    CGRect		result = CGRectMake(originX, originY, width, height);
    return result;
}

-(NSString*) entityName
{
    return @"rect";
}



-(BOOL)	hitTest:(CGPoint) testPoint
{
    BOOL	result = [super hitTest:testPoint];
    [self asCGRect];
    return result;
}

-(BOOL) isClosed
{
    BOOL	result = YES;
    return result;
}


-(BOOL) isFillable
{
    BOOL result = YES;
    return result;
}

-(CGPathRef) newQuartzPath
{
    CGPathRef result = 0;
    CGRect theRectangle = [self asCGRect];
    if(!CGRectIsEmpty(theRectangle))
    {
        CGMutablePathRef	mutableResult = CGPathCreateMutable();
        
        NSString* radiusXString = [self.attributes objectForKey:@"rx"];
        NSString* radiusYString = [self.attributes objectForKey:@"ry"];
        
        if(radiusXString == nil) radiusXString = radiusYString;
        if(radiusYString == nil) radiusYString = radiusXString;
        
        if([radiusXString doubleValue] > 0 && [radiusYString doubleValue] > 0.0)
            // a round rect
        {
            CGFloat	xRadius = [radiusXString floatValue];
            CGFloat yRadius = [radiusYString	floatValue];
            BOOL	useLargeArc = NO;
            BOOL	sweepIt = YES;
            
            if(xRadius > theRectangle.size.width/2.0)
            {
                xRadius = theRectangle.size.width/2.0f;
            }
            
            if(yRadius > theRectangle.size.height/2.0)
            {
                yRadius = theRectangle.size.height/2.0f;
            }
            
            CGPathMoveToPoint(mutableResult, NULL, theRectangle.origin.x+xRadius, theRectangle.origin.y);
            
            CGPathAddLineToPoint(mutableResult, NULL,
                                 theRectangle.origin.x+theRectangle.size.width-xRadius,
                                 theRectangle.origin.y);
            
            AddSVGArcToPath(mutableResult, xRadius,  yRadius,
                            M_PI_2,
                            useLargeArc, sweepIt,
                            theRectangle.origin.x+theRectangle.size.width, theRectangle.origin.y+yRadius);
            
            CGPathAddLineToPoint(mutableResult, NULL,
                                 theRectangle.origin.x+theRectangle.size.width,
                                 theRectangle.origin.y+theRectangle.size.height-yRadius);
            
            
            
            AddSVGArcToPath(mutableResult, xRadius,  yRadius,
                            M_PI_2,
                            useLargeArc, sweepIt,
                            theRectangle.origin.x+theRectangle.size.width-xRadius,
                            theRectangle.origin.y+theRectangle.size.height);
            
            CGPathAddLineToPoint(mutableResult, NULL,
                                 theRectangle.origin.x+xRadius,
                                 theRectangle.origin.y+theRectangle.size.height);
            
            AddSVGArcToPath(mutableResult, xRadius,  yRadius,
                            M_PI_2,
                            useLargeArc, sweepIt,
                            theRectangle.origin.x,
                            theRectangle.origin.y+theRectangle.size.height-yRadius);
            
            
            
            CGPathAddLineToPoint(mutableResult, NULL,
                                 theRectangle.origin.x,
                                 theRectangle.origin.y+yRadius);
            
            
            AddSVGArcToPath(mutableResult, xRadius,  yRadius,
                            M_PI_2,
                            useLargeArc, sweepIt,
                            theRectangle.origin.x+xRadius,
                            theRectangle.origin.y);
            
            
            CGPathCloseSubpath(mutableResult);
            
        }
        else
        {
            CGPathAddRect(mutableResult,NULL, theRectangle);
        }
        
        result = CGPathCreateCopy(mutableResult);
        CGPathRelease(mutableResult);
    }
    else
    {
        result = 0;
    }
    return result;
}

@end

@implementation GHPath
-(NSString*) renderingPath
{
    NSString* result = [self.attributes objectForKey:@"d"];
    return result;
}

-(BOOL) isClosed
{
    BOOL	result = [[self.renderingPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] hasSuffix:@"z"];
    return result;
}


-(BOOL) isFillable
{
    BOOL result = YES;
    return result;
}

-(CGPathRef) newQuartzPath
{
    CGAffineTransform offsetTransform = CGAffineTransformIdentity;
    id xValue = [self.attributes objectForKey:@"x"];
    id yValue = [self.attributes objectForKey:@"y"];
    
    if(xValue != nil || yValue != nil)
    {
        offsetTransform =  CGAffineTransformMakeTranslation([xValue floatValue], [yValue floatValue]);
    }
    CGPathRef result = [SVGPathGenerator newCGPathFromSVGPath:self.renderingPath whileApplyingTransform:offsetTransform];
    return result;
}

-(NSString*) entityName
{
    return @"path";
}


@end

@implementation GHSwitchGroup

-(NSArray*)children
{
    NSArray* superChildren = [super children];
    NSMutableArray* mutableResult = [[NSMutableArray alloc] initWithCapacity:[superChildren count]];
    if([superChildren count])
    {
        CFArrayRef langs = CFLocaleCopyPreferredLanguages();
        CFStringRef langCode = CFArrayGetValueAtIndex (langs, 0);
        NSString* twoCharISOLanguage = [[NSString stringWithString:(__bridge NSString*)langCode] substringToIndex:2];
        
        CFRelease(langs);
        
        for(id aChild in superChildren)
        {
            if([aChild respondsToSelector:@selector(environmentOKWithISOCode:)])
                
            {
                if([(SVGAttributedObject*)aChild environmentOKWithISOCode:twoCharISOLanguage])
                {
                    [mutableResult addObject:aChild];
                    break;
                }
            }
            
        }
    }
    return [mutableResult copy];
}

@end

@interface GHShapeGroup()
{
@private
    CGAffineTransform	transform;
}
-(BOOL) usesParentsCoordinates;
-(void)setCloneTransform:(CGAffineTransform)newTransform;
@end

@implementation GHShapeGroup
@synthesize children=_children, transform, childDefinitions = _childDefinitions;

-(BOOL) hidden
{
    BOOL result = [super hidden];
    return result;
}

-(NSString*) entityName
{
    return @"g";
}

-(CGAffineTransform) calculateTransform
{
    CGAffineTransform   result = CGAffineTransformIdentity;
    NSString*	transformAttribute = [self.attributes objectForKey:@"transform"];
    if(transformAttribute != nil)
    {
        result = SVGTransformToCGAffineTransform(transformAttribute);
    }
    
    NSString* xString = [self.attributes objectForKey:@"x"];
    CGFloat xOffset = [xString floatValue];
    if(xOffset != 0 && xOffset == xOffset)
    {
        result = CGAffineTransformTranslate(result, xOffset, 0.0);
    }
    
    
    NSString* yString = [self.attributes objectForKey:@"y"];
    CGFloat yOffset = [yString floatValue];
    if(yOffset != 0 && yOffset == yOffset)
    {
        result = CGAffineTransformTranslate(result, 0.0, yOffset);
    }
    
    return result;
}

-(instancetype) cloneWithOverridingDictionary:(NSDictionary*)overrideAttributes
{
    GHShapeGroup* result = [super cloneWithOverridingDictionary:overrideAttributes];
    result.childDefinitions = self.childDefinitions;
    
    
    CGAffineTransform newTransform = [result calculateTransform];
    
    [result setCloneTransform:newTransform];
    
    return result;
}
-(void)setCloneTransform:(CGAffineTransform)newTransform
{
    transform = newTransform;
}

+(NSDictionary*) nameToClassMap
{
    static NSDictionary* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        NSDictionary* result = @{@"g":[GHShapeGroup class],
                                 @"switch":[GHSwitchGroup class],
                                 @"defs":[GHDefinitionGroup class],
                                 @"rect":[GHRectangle class],
                                 @"text":[GHText class],
                                 @"textArea":[GHTextArea class],
                                 @"path":[GHPath class],
                                 @"polygon":[GHPolygon class],
                                 @"polyline":[GHPolyline class],
                                 @"ellipse":[GHEllipse class],
                                 @"circle":[GHCircle class],
                                 @"line":[GHLine class],
                                 @"image":[GHImage class],
                                 @"use":[GHRenderableObjectPlaceholder class],
                                 @"clipPath":[GHClipGroup class],
                                 @"mask":[GHMask class],
                                 @"solidColor":[GHSolidColor class],
                                 @"linearGradient":[GHLinearGradient class],
                                 @"radialGradient":[GHRadialGradient class],
                                 @"style":[GHStyle class]
                                 };
        sResult = result;
    });
    return sResult;
    
}

-(NSArray*) children
{
    NSArray* result = _children;
    if(result == nil)
    {
        NSMutableArray* mutableChildren = [[NSMutableArray alloc] initWithCapacity:[self.childDefinitions count]];
        
        NSDictionary* groupsFontAttributes = [SVGTextUtilities fontAttributesFromSVGAttributes:self.attributes];
        NSMutableDictionary* groupsSharedAttributes = [NSMutableDictionary dictionary];
        
        NSString* fillSetting = [self.attributes objectForKey:@"fill"];
        if([fillSetting length])
        {
            [groupsSharedAttributes setObject:fillSetting forKey:@"fill"];
        }
        
        NSString* strokeSetting = [self.attributes objectForKey:@"stroke"];
        if([strokeSetting length])
        {
            [groupsSharedAttributes setObject:strokeSetting forKey:@"stroke"];
        }
        
        NSString* colorSetting = [self.attributes objectForKey:@"color"];
        if([colorSetting length] && ![colorSetting isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:colorSetting forKey:@"color"];
        }
        
        NSString* fillOpacitySetting = [self.attributes objectForKey:@"fill-opacity"];
        if([fillOpacitySetting length] && ![fillOpacitySetting isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:fillOpacitySetting forKey:@"fill-opacity"];
        }
        
        NSString* xmlBaseString = [self.attributes objectForKey:@"xml:base"];
        if([xmlBaseString length] && ![xmlBaseString isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:xmlBaseString forKey:@"xml:base"];
        }
        
        NSString* strokeOpacitySetting = [self.attributes objectForKey:@"stroke-opacity"];
        if([strokeOpacitySetting length] && ![strokeOpacitySetting isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:strokeOpacitySetting forKey:@"stroke-opacity"];
        }
        
        NSString* stopColorSetting = [self.attributes objectForKey:@"stop-color"];
        if([stopColorSetting length] && ![stopColorSetting isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:stopColorSetting forKey:@"stop-color"];
        }
        
        NSString* stopOpacitySetting = [self.attributes objectForKey:@"stop-opacity"];
        if([stopOpacitySetting length] && ![stopOpacitySetting isEqualToString:@"inherit"])
        {
            [groupsSharedAttributes setObject:stopOpacitySetting forKey:@"stop-opacity"];
        }
        
        NSDictionary* nameToClassMap = [GHShapeGroup nameToClassMap];
        
        for(id aChild in self.childDefinitions)
        {
            if([aChild isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* aDefinition = (NSDictionary*)aChild;
                
                NSDictionary* childsAttributes = [aDefinition objectForKey:kAttributesElementName];
                if([childsAttributes count] && [groupsSharedAttributes count])
                {
                    NSMutableDictionary* mutableChildAttributes = [groupsSharedAttributes mutableCopy];
                    
                    NSArray* keys = [childsAttributes allKeys];
                    for(id aKey in keys)
                    {
                        NSString* aValue = [childsAttributes objectForKey:aKey];
                        if(![aValue isEqualToString:@"inherit"])
                        {
                            [mutableChildAttributes setObject:aValue forKey:aKey];
                        }
                    }
                    keys = [mutableChildAttributes allKeys];
                    for(id aKey in keys)
                    {
                        NSString* aValue = [mutableChildAttributes objectForKey:aKey];
                        if([aValue isEqualToString:@"inherit"])
                        {// didn't actually find any inherited property
                            [mutableChildAttributes removeObjectForKey:aKey];
                        }
                    }
                    childsAttributes = mutableChildAttributes;
                }
                else if([groupsSharedAttributes count])
                {
                    childsAttributes = groupsSharedAttributes;
                }
                
                NSString*	elementName = [aDefinition objectForKey:kElementName];
                if(([elementName isEqualToString:@"g"] || [elementName isEqualToString:@"text"] || [elementName isEqualToString:@"switch"])
                   && [groupsFontAttributes count])
                {
                    if([childsAttributes count])
                    {
                        NSMutableDictionary* mutableChildAttributes = [groupsFontAttributes mutableCopy];
                        [mutableChildAttributes addEntriesFromDictionary:childsAttributes];
                        childsAttributes = mutableChildAttributes;
                    }
                    else
                    {
                        childsAttributes = groupsFontAttributes;
                    }
                }
                
                if(childsAttributes != [aDefinition objectForKey:kAttributesElementName]
                   && [childsAttributes count])
                {
                    NSMutableDictionary* mutableDefinition = [aDefinition mutableCopy];
                    [mutableDefinition setObject:childsAttributes forKey:kAttributesElementName];
                    aDefinition = [mutableDefinition copy];
                }
                
                if([elementName isEqualToString:@"image"]) // images are created differently from other SVGAttributedObjects, it might be either a bitmap or an SVG.
                {
                    id  anImage = [GHImage newImageWithDictionary:aDefinition];
                    if(anImage != nil)
                    {
                        [mutableChildren addObject:anImage];
                    }
                }
                else
                {
                    Class theClass = [nameToClassMap valueForKey:elementName];
                    if(theClass != nil)
                    {
                        GHAttributedObject* aChild = [[theClass alloc] initWithDictionary:aDefinition];
                        if(aChild != nil)
                        {
                            [mutableChildren addObject:aChild];
                        }
                    }
                }
            }
        }
        result = _children = [mutableChildren copy];
        
    }
    return result;
}

-(instancetype) initWithDictionary:(NSDictionary*)theDefinition
{
    if(nil != (self = [super initWithDictionary:theDefinition]))
    {
        transform = [self calculateTransform];
        _childDefinitions = [theDefinition objectForKey:kContentsElementName];
        
    }
    return self;
}

-(NSUInteger)calculatedHash
{
    NSUInteger result = [super calculatedHash];
    result += [_childDefinitions hash];
    
    return result;
}

-(BOOL)isEqual:(id)object
{
    BOOL result = object == self;
    
    if(!result && [super isEqual:object])
    {
        GHShapeGroup* objectAsShapeGroup = (GHShapeGroup*)object;
        result = [self.children isEqual:objectAsShapeGroup.children];
    }
    
    return result;
}


-(BOOL) usesParentsCoordinates
{
    BOOL result = NO;
    if([[self.attributes objectForKey:@"clipPathUnits"] isEqualToString:@"objectBoundingBox"])
    {
        result = YES;
    }
    else  if([[self.attributes objectForKey:@"maskContentUnits"] isEqualToString:@"objectBoundingBox"])
    {
        result = YES;
    }
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = CGRectZero;
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        if([aChild environmentOKWithSVGContext:svgContext])
        {
            CGRect childRect = [aChild getBoundingBoxWithSVGContext:svgContext];
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

-(void) renderChildrenIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    CGContextSaveGState(quartzContext);
    CGAffineTransform   myTransform = self.transform;
    CGContextConcatCTM(quartzContext, myTransform);
    [GHRenderableObject	setupContext:quartzContext withAttributes:self.attributes  withSVGContext:svgContext];
    id clippingObject = [GHClipGroup clipObjectForAttributes:self.attributes withSVGContext:svgContext];
    if(clippingObject)
    {
        [clippingObject addToClipForContext:quartzContext  withSVGContext:svgContext objectBoundingBox:CGRectZero];
    }
    UIColor* savedColor = [svgContext currentColor];
    UIColor* colorToDefaultTo = nil;
    NSString* colorString = [self.attributes objectForKey:@"color"];
    if([colorString isEqualToString:@"inherit"] || [colorString length] == 0)
    {
        colorToDefaultTo = savedColor;
    }
    else if([colorString length])
    {
        colorToDefaultTo = [svgContext colorForSVGColorString:colorString];
    }
    
    
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        if([aChild environmentOKWithSVGContext:svgContext])
        {
            [svgContext setCurrentColor:colorToDefaultTo];
            [aChild renderIntoContext:quartzContext withSVGContext:svgContext];
        }
    }
    [svgContext setCurrentColor:savedColor];
    CGContextRestoreGState(quartzContext);
}

-(UIImage*) newClipMaskWithSVGContext:(id<SVGContext>)svgContext andObjectBox:(CGRect)objectBox
{
    UIImage* result = nil;
    CGRect clipRect = [self getBoundingBoxWithSVGContext:svgContext];
    if(!CGRectIsNull(clipRect))
    {
        CGContextRef bitmapContext = BitmapContextCreate ((size_t)ceilf(clipRect.size.width),
                                                          (size_t)ceilf(clipRect.size.height));
        
        CGContextTranslateCTM(bitmapContext, clipRect.origin.x, clipRect.origin.y);
        
        [self renderChildrenIntoContext:bitmapContext withSVGContext:svgContext];
        CGImageRef bitmap = CGBitmapContextCreateImage (bitmapContext);
        if(bitmap != 0)
        {
            result  = [UIImage imageWithCGImage:bitmap];
            CGImageRelease(bitmap);
        }
        
        CFRelease(bitmapContext);
    }
    return result;
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    CGContextConcatCTM(quartzContext, self.transform);
    [GHRenderableObject	setupContext:quartzContext withAttributes:self.attributes  withSVGContext:svgContext];
    ClippingType type = [self getClippingTypeWithSVGContext:svgContext];
    
    
    
    if(type == kMixedClippingType || type == kFontGlyphClippingType)
    {
        UIImage* maskImage = [self newClipMaskWithSVGContext:svgContext andObjectBox:objectBox];
        if(maskImage != nil)
        {
            CGRect clipRect = [GHRenderableObject boundingBoxForRenderableObject:self withSVGContext:svgContext  givenParentObjectsBounds:objectBox];
            
            CGContextClipToMask(quartzContext, clipRect, maskImage.CGImage);
        }
    }
    else
    {
        
        NSString* clipPathName = [SVGToQuartz valueForStyleAttribute:@"clip-path" fromDefinition:self.attributes];
        if([clipPathName length])
        {
            id  aClipGroup = [svgContext objectAtURL:clipPathName];
            
            if([aClipGroup respondsToSelector:@selector(addToClipForContext:withSVGContext:objectBoundingBox:)])
            {
                [aClipGroup addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
            }
        }
        
        BOOL useClipPath = YES;
        for(int i = 0; i<2; i++)
        {
            CGContextSaveGState(quartzContext);
            
            id widthValue = [self.attributes objectForKey:@"width"];
            id heightValue = [self.attributes objectForKey:@"height"];
            CGFloat width = widthValue?[widthValue floatValue]:1.0f;
            CGFloat height = heightValue?[heightValue floatValue]:1.0f;
            
            if([self usesParentsCoordinates]
               && width > 0 && height > 0)
            {
                CGContextTranslateCTM(quartzContext, objectBox.origin.x, objectBox.origin.y);
                CGContextScaleCTM(quartzContext, (objectBox.size.width*width), (objectBox.size.height*height));
            }
            
            BOOL hasClipPath = NO;
            NSArray* myChildren = self.children;
            for(id aChild in myChildren)
            {
                if([aChild environmentOKWithSVGContext:svgContext])
                {
                    if(useClipPath && [aChild respondsToSelector:@selector(attributes)]  )
                    {
                        id clipObject = [GHClipGroup clipObjectForAttributes:[(SVGAttributedObject*)aChild attributes] withSVGContext:svgContext];
                        if(clipObject != nil)
                        {
                            hasClipPath = YES;
                            CGRect childRect = [aChild getBoundingBoxWithSVGContext:svgContext];
                            [clipObject addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:childRect];
                        }
                        else
                        {
                            [aChild addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
                        }
                    }
                    else
                    {
                        [aChild addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
                    }
                }
            }
            
            CGContextRestoreGState(quartzContext);
            if(!CGContextIsPathEmpty(quartzContext))
            {
                if(type == kEvenOddPathClippingType)
                {
                    CGContextEOClip(quartzContext);
                }
                else
                {
                    CGContextClip(quartzContext);
                }
            }
            useClipPath = NO;
            if(!hasClipPath)
            {
                break;
            }
        }
    }
    
}

-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        if([aChild environmentOKWithSVGContext:svgContext])
        {
            [aChild addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
        }
    }
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType    result = kNoClippingType;
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        ClippingType childClippingType = [aChild getClippingTypeWithSVGContext:svgContext];
        if(result == kNoClippingType)
        {
            result = childClippingType;
        }
        else if(result != childClippingType)
        {
            result = kMixedClippingType;
        }
    }
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    [self renderChildrenIntoContext:quartzContext withSVGContext:svgContext];
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint withSVGContext:(id<SVGContext>)svgContext
{
    id<GHRenderable> result = nil;
    CGAffineTransform invertedTransform = CGAffineTransformInvert(self.transform);
    CGPoint relativePoint = CGPointApplyAffineTransform(testPoint, invertedTransform);
    
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        if([aChild environmentOKWithSVGContext:svgContext])
        {
            id<GHRenderable> foundShape = [aChild findRenderableObject:relativePoint withSVGContext:svgContext];
            if(foundShape != nil)
            {
                result = foundShape;
            }
        }
    }
    return result;
}
-(void) addNamedObjects:(NSMutableDictionary*)namedObjectsMap
{
    NSString* myName = [self.attributes objectForKey:@"id"];
    if([myName isKindOfClass:[NSString class]] && [myName length])
    {
        [namedObjectsMap  setValue:self forKey:myName];
    }
    else
    {
        myName = [self.attributes objectForKey:@"xml:id"];
        if([myName isKindOfClass:[NSString class]] && [myName length])
        {
            [namedObjectsMap  setValue:self forKey:myName];
        }
    }
    
    NSArray* myChildren = self.children;
    for(id aChild in myChildren)
    {
        if([aChild respondsToSelector:@selector(addNamedObjects:)])
        {
            [aChild addNamedObjects:namedObjectsMap];
        }
    }
}

@end

@implementation GHDefinitionGroup

// definition groups don't render on screen
-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint  withSVGContext:(id<SVGContext>)svgContext
{
    id<GHRenderable> result = nil;
    return result;
}
-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    
}

@end

@interface GHStyle()
@property(nonatomic, strong) NSDictionary<NSString*, GHCSSStyle*>* classes;

@end

@implementation GHStyle

-(instancetype) initWithDictionary:(NSDictionary*)theDefinition
{
    if(nil != (self = [super initWithDictionary:theDefinition]))
    {
        NSString* contents = [theDefinition objectForKey:kContentsElementName];
        _classes = [GHCSSStyle stylesForString:contents];
    }
    return self;
}

-(StyleElementType) styleType
{
    StyleElementType result = kStyleTypeCSS;
    NSString* explicitType = [self.attributes valueForKey:@"type"];
    if(explicitType.length > 0 && ![explicitType isEqualToString:@"text/css"])
    {
        result = kStyleTypeUnsupported;
    }
    return result;
}
@end

@implementation GHClipGroup

+(id)clipObjectForAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext
{
    id result = nil;
    
    NSString* clipPathName = [SVGToQuartz valueForStyleAttribute:@"clip-path" fromDefinition:attributes];
    if([clipPathName length])
    {
        id  aClipGroup = [svgContext objectAtURL:clipPathName];
        
        if([aClipGroup respondsToSelector:@selector(addToClipForContext:withSVGContext:objectBoundingBox:)])
        {
            result = aClipGroup;
        }
    }
    if(result == nil)
    {
        NSString* maskString = [attributes objectForKey:@"mask"];
        if(IsStringURL(maskString))
        {
            id  maskObject = [svgContext objectAtURL:maskString];
            if([maskObject respondsToSelector:@selector(addToClipForContext:withSVGContext:objectBoundingBox:)])
            {
                result = maskObject;
            }
        }
    }
    return result;
}

// clip objects groups don't render on screen
-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint  withSVGContext:(id<SVGContext>)svgContext
{
    id<GHRenderable> result = nil;
    return result;
}
-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox;
{
    if([self usesParentsCoordinates])
    {
        [super addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
    }
    else
    {
        CGRect zeroRect = CGRectZero;
        [super addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:zeroRect];
    }
}

@end

@implementation GHMask

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kMixedClippingType;
    return result;
}

-(UIImage*) newClipMaskWithSVGContext:(id<SVGContext>)svgContext andObjectBox:(CGRect)objectBox
{
    UIImage* result = 0;
    CGRect clipRect = [GHRenderableObject boundingBoxForRenderableObject:self withSVGContext:svgContext  givenParentObjectsBounds:objectBox];
    
    if(CGRectIsNull(clipRect))
    {
        clipRect = [self getBoundingBoxWithSVGContext:svgContext];
    }
    if(!CGRectIsNull(clipRect))
    {
        CGContextRef bitmapContext = BitmapContextCreate ((size_t)ceilf(clipRect.size.width),
                                                          (size_t)ceilf(clipRect.size.height));
        
        CGContextSetFillColorWithColor(bitmapContext, [UIColor blackColor].CGColor);
        CGContextFillRect(bitmapContext, CGRectMake(0, 0, clipRect.size.width, clipRect.size.height));
        
        CGContextSetFillColorWithColor(bitmapContext, [UIColor blackColor].CGColor);
        CGContextSetStrokeColorWithColor(bitmapContext, [UIColor blackColor].CGColor);
        
        CGFloat width =    [[self.attributes objectForKey:@"width"] floatValue];
        CGFloat height = [[self.attributes objectForKey:@"height"] floatValue];
        
        if([self usesParentsCoordinates]
           && width > 0 && height > 0)
        {
            CGContextScaleCTM(bitmapContext, (clipRect.size.width*width), (clipRect.size.height*height));
        }
        
        [self renderChildrenIntoContext:bitmapContext withSVGContext:svgContext];
        CGContextFlush(bitmapContext);
        CGImageRef bitmap = CGBitmapContextCreateImage (bitmapContext);
        if(bitmap != 0)
        {
            size_t      bytesPerRow = CGImageGetBytesPerRow(bitmap);
            size_t      bitmapWidth = CGImageGetWidth(bitmap);
            size_t      bitmapHeight = CGImageGetHeight(bitmap);
            
            CFDataRef bitmapData = CGDataProviderCopyData(CGImageGetDataProvider(bitmap));
            CGImageRelease(bitmap);
            CFIndex dataSize = (CFIndex)(bitmapWidth*bitmapHeight);
            CFMutableDataRef greyData = CFDataCreateMutable(NULL, dataSize);
            CFDataSetLength(greyData, dataSize);
            UInt8* greyscaleDestinationPtr = CFDataGetMutableBytePtr(greyData);
            const UInt8* rgbSourcePtr = CFDataGetBytePtr(bitmapData);
            for(size_t row = 0; row < bitmapHeight; row++)
            {
                const UInt8* rowPtr = rgbSourcePtr;
                for(size_t column = 0; column < bitmapWidth; column++)
                {
                    UInt8   red = *rowPtr++;
                    UInt8   green = *rowPtr++;
                    UInt8   blue = *rowPtr++;
                    UInt8   alpha = * rowPtr++;
                    
                    CGFloat redFloat = (float)red/255.0f;
                    CGFloat greenFloat = (float)green/255.0f;
                    CGFloat blueFloat = (float)blue/255.0f;
                    CGFloat alphaFloat = (float)alpha/255.0f;
                    
                    CGFloat greyFloat = (0.2125f*redFloat + 0.7154f*greenFloat + 0.0721f*blueFloat)*alphaFloat;
                    greyFloat = 1.0f-greyFloat;
                    greyFloat*= 255.0f;
                    
                    UInt8   grey =  (UInt8)round(greyFloat);
                    *greyscaleDestinationPtr++ = grey;
                    
                }
                rgbSourcePtr += bytesPerRow;
            }
            CGDataProviderRef greyProvider = CGDataProviderCreateWithCFData(greyData);
            CGImageRef mask = CGImageMaskCreate(bitmapWidth,
                                                bitmapHeight,
                                                8,
                                                8,
                                                bitmapWidth,
                                                greyProvider,
                                                NULL, // decode should be NULL
                                                FALSE // shouldInterpolate
                                                );
            CGDataProviderRelease(greyProvider);
            CFRelease(greyData);
            if(mask != 0)
            {
                result = [UIImage imageWithCGImage:mask];
                CGImageRelease(mask);
            }
            CFRelease(bitmapData);
        }
        
        CFRelease(bitmapContext);
    }
    return result;
}


-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect result = [super getBoundingBoxWithSVGContext:svgContext];
    
    if([self usesParentsCoordinates])
    {
        
        CGFloat originX = [[self.attributes objectForKey:@"x"] floatValue];
        CGFloat originY = [[self.attributes objectForKey:@"y"] floatValue];
        CGFloat width =    [[self.attributes objectForKey:@"width"] floatValue];
        CGFloat height = [[self.attributes objectForKey:@"height"] floatValue];
        
        if(width <= 0) width = 1.0;
        if(height <= 0) height = 1.0;
        
        result = CGRectMake(result.origin.x + originX*result.size.width
                            , result.origin.y + originY*result.size.height
                            , width*result.size.width, height*result.size.height);
        
    }
    
    return result;
}

@end

@implementation GHRenderableObjectPlaceholder

-(NSString*) prototypesName
{
    NSString* result  = @"";
    id  xlinkValue = [self.attributes objectForKey:@"xlink:href"];
    if([xlinkValue isKindOfClass:[NSString class]] && [xlinkValue hasPrefix:@"#"])
    {
        result = [xlinkValue substringFromIndex:1];
    }
    
    return result;
}

-(id<GHRenderable>)  concreteObjectForSVGContext:(id<SVGContext>)svgContext excludingPrevious:(NSMutableSet*)exclusionSet
{
    id<GHRenderable>   result = nil;
    if(![exclusionSet containsObject:self])
    {
        NSString*   prototypesName = [self prototypesName];
        id  prototypeObject = [svgContext objectNamed:prototypesName];
        if([prototypeObject respondsToSelector:@selector(cloneWithOverridingDictionary:)])
        {
            result = [prototypeObject cloneWithOverridingDictionary:self.attributes];
        }
        if([result isKindOfClass:[GHRenderableObjectPlaceholder class]])
        {
            GHRenderableObjectPlaceholder* subPlaceholder = (GHRenderableObjectPlaceholder*)result;
            if(exclusionSet == nil)
            {
                exclusionSet = [[NSMutableSet alloc] initWithCapacity:3];
            }
            else
            {
                [exclusionSet addObject:self];
            }
            result = [subPlaceholder concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
        }
    }
    
    return result;
}

-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = kNoClippingType;
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    if(myConcrete != self)
    {
        result = [myConcrete getClippingTypeWithSVGContext:svgContext];
    }
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    if(myConcrete != self)
    {
        BOOL isSetToHidden= myConcrete.hidden;
        if(!isSetToHidden)
        {
            [myConcrete renderIntoContext:quartzContext withSVGContext:svgContext];
        }
    }
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{// base class doesn't know how to do this.
    CGRect result = CGRectZero;
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    if(myConcrete != self)
    {
        result = [myConcrete getBoundingBoxWithSVGContext:svgContext];
    }
    return result;
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint withSVGContext:(id<SVGContext>)svgContext
{
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    id<GHRenderable> result = [myConcrete findRenderableObject:testPoint withSVGContext:svgContext];
    return result;
}

-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    [myConcrete addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}

-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    NSMutableSet*   exclusionSet = nil;
    id<GHRenderable> myConcrete = [self concreteObjectForSVGContext:svgContext excludingPrevious:exclusionSet];
    [myConcrete addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}

@end


@implementation SVGAttributedObject


-(BOOL)environmentOKWithISOCode:(NSString*)isoLanguage
{
    BOOL result = YES;
    NSArray* validLanguageCodes = [(NSString*)[self.attributes objectForKey:@"systemLanguage"] componentsSeparatedByString:@","];
    if([validLanguageCodes count])
    {
        result = NO;
        for(NSString* aValidLanguageCode in validLanguageCodes)
        {
            NSString* trimmedValidLanguageCode = [aValidLanguageCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([trimmedValidLanguageCode hasPrefix:isoLanguage])
            {
                result = YES;
                break;
            }
            
        }
    }
    if(result == YES)
    {
        NSArray* requiredExtensions = [(NSString*)[self.attributes objectForKey:@"requiredExtensions"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(NSString* anExtension in requiredExtensions)
        {
            if([anExtension length])
            {
                result = NO;
                break;
            }
        }
    }
    
    if(result == YES)
    {
        NSArray* requiredFormats = [(NSString*)[self.attributes objectForKey:@"requiredFormats"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(NSString* aFormat in requiredFormats)
        {
            if([aFormat hasPrefix:@"image"])
            {
                if([aFormat isEqualToString:@"image/jpg"]
                   || [aFormat isEqualToString:@"image/jpeg"]
                   || [aFormat isEqualToString:@"image/svg+xml"]
                   || [aFormat isEqualToString:@"image/png"])
                {
                    
                }
                else
                {
                    result = NO;
                    break;
                }
                
            }
            else
            {
                result = NO;
                break;
            }
        }
        
    }
    
    if(result == YES)
    {
        NSArray* requiredFeatures = [(NSString*)[self.attributes objectForKey:@"requiredFeatures"] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(NSString* aFeature in requiredFeatures)
        {
            static NSSet* supportedFeatures = nil;
            static dispatch_once_t  done;
            dispatch_once(&done, ^{
                supportedFeatures = [NSSet setWithObjects:
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#CoreAttribute",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#Structure",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#ConditionalProcessing",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#ConditionalProcessingAttribute",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#Image",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#Shape",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#Text",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#PaintAttribute",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#OpacityAttribute",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#GraphicsAttribute",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#Gradient",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#SolidColor",
                                     @"http://www.w3.org/Graphics/SVG/feature/1.2/#SVG-static",
                                     
                                     nil];
            });
            if(![supportedFeatures containsObject:aFeature])
            {
                result = NO;
                break;
            }
        }
    }
    
    return result;
}

-(BOOL)environmentOKWithSVGContext:(id<SVGContext>)svgContext
{
    BOOL result = [self environmentOKWithISOCode:[svgContext isoLanguage]];
    if(result)
    {
        BOOL isSetToHidden= [SVGToQuartz attributeHasDisplaySetToNone:self.attributes];
        if(isSetToHidden)
        {
            result = NO;
        }
    }
    return result;
}

-(BOOL) hidden
{
    BOOL result = [SVGToQuartz attributeHasDisplaySetToNone:self.attributes];
    return result;
}


@end

@implementation GHFill

-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
    // can't actually render
}

-(void) addNamedObjects:(NSMutableDictionary*)namedObjectsMap
{
    NSString* myName = [self.attributes objectForKey:@"id"];
    if([myName isKindOfClass:[NSString class]] && [myName length])
    {
        [namedObjectsMap  setValue:self forKey:myName];
    }
    else
    {
        myName = [self.attributes objectForKey:@"xml:id"];
        if([myName isKindOfClass:[NSString class]] && [myName length])
        {
            [namedObjectsMap  setValue:self forKey:myName];
        }
    }
}


@end

@implementation GHSolidColor
-(UIColor*) asColorWithSVGContext:(id<SVGContext>)svgContext
{
    UIColor* result = nil;
    NSString* fillString = [self.attributes objectForKey:@"solid-color"];
    if([fillString length])
    {
        result = [svgContext colorForSVGColorString:fillString];
    }
    return result;
}
@end
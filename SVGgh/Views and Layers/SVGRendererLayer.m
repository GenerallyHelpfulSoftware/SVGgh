//
//  SVGRendererLayer.m
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
//  Created by Glenn Howes on 1/15/11.

#import "SVGRendererLayer.h"
#import "SVGUtilities.h"

@interface SVGRendererLayer (Private)
-(CGRect) makeDrawingRect;
@end

@implementation SVGRendererLayer(Private)

-(CGRect) makeDrawingRect
{	
	CGRect	myBounds = self.bounds;
	CGRect	preferredRect = self.renderer.viewRect;
    
    
    if(CGRectIsEmpty(preferredRect))
    {
        preferredRect = myBounds;
    }
    
    
    
	CGFloat	nativeWidth = preferredRect.size.width;
	CGFloat	nativeHeight = preferredRect.size.height;
	CGFloat	nativeAspectRatio = nativeWidth/nativeHeight;
	CGFloat	boundedAspectRatio = myBounds.size.width/myBounds.size.height;
	
	CGFloat	paintedWidth = myBounds.size.width;
	CGFloat	paintedHeight = myBounds.size.height;
    CGRect	result = myBounds;
    
    NSString* myGravity = self.contentsGravity;
    if([myGravity isEqualToString:kCAGravityResizeAspect])
    {
	
        if(nativeAspectRatio >= boundedAspectRatio) // blank space on top and bottom
        {
            paintedHeight = paintedWidth/nativeAspectRatio;
        }
        else 
        {
            paintedWidth = paintedHeight*nativeAspectRatio;
        }
        paintedWidth = rintf(paintedWidth);
        paintedHeight = rintf(paintedHeight);
        
        CGFloat xOrigin = (myBounds.size.width-paintedWidth)/2.0f;
        CGFloat yOrigin = (myBounds.size.height-paintedHeight)/2.0f;
        result = CGRectMake(xOrigin, yOrigin, paintedWidth, paintedHeight);
    }
    else if([myGravity isEqualToString:kCAGravityResizeAspectFill])
    {
        if(nativeAspectRatio <= boundedAspectRatio) // blank space on top and bottom
        {
            paintedHeight = paintedWidth/nativeAspectRatio;
        }
        else
        {
            paintedWidth = paintedHeight*nativeAspectRatio;
        }
        paintedWidth = rintf(paintedWidth);
        paintedHeight = rintf(paintedHeight);
        
        CGFloat xOrigin = (myBounds.size.width-paintedWidth)/2.0f;
        CGFloat yOrigin = (myBounds.size.height-paintedHeight)/2.0f;
        result = CGRectMake(xOrigin, yOrigin, paintedWidth, paintedHeight);
    }
    else if([myGravity isEqualToString:kCAGravityBottomLeft])
    { // flipped
        
        result = CGRectMake(0, 0, preferredRect.size.width, preferredRect.size.height);
    }
    
    result = CGRectIntegral(result);
	return result;
}

@end



@implementation SVGRendererLayer
-(instancetype)init
{
    if(nil != (self = [super init]))
    {
        CGFloat screenScale = [UIScreen mainScreen].scale;
        self.contentsScale = screenScale;
        self.needsDisplayOnBoundsChange = YES;
    }
    return self;
}
-(instancetype) initWithLayer:(id)layer
{
    if(nil != (self = [super initWithLayer:layer]))
    {
        CGFloat screenScale = [UIScreen mainScreen].scale;
        self.contentsScale = screenScale;
        self.needsDisplayOnBoundsChange = YES;

    }
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if(nil != (self = [super initWithCoder:aDecoder]))
    {
        CGFloat screenScale = [UIScreen mainScreen].scale;
        self.contentsScale = screenScale;
        self.needsDisplayOnBoundsChange = YES;

    }
    return self;
}


-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint
{
	CGAffineTransform pointTransformer = CGAffineTransformIdentity;
	CGRect drawRect = [self makeDrawingRect];
	CGRect	preferredRect = self.renderer.viewRect;
	CGFloat	nativeWidth = preferredRect.size.width;
	CGFloat	widthScale = nativeWidth/drawRect.size.width;
	CGFloat	nativeHeight = preferredRect.size.height;
	CGFloat	heightScale = nativeHeight/drawRect.size.height;
	pointTransformer = CGAffineTransformScale(pointTransformer,widthScale, heightScale);
	pointTransformer = CGAffineTransformTranslate(pointTransformer, -1.0f*drawRect.origin.x, -1.0f*drawRect.origin.y);
	
	CGPoint transformedPoint = CGPointApplyAffineTransform(testPoint,pointTransformer);
	
	id<GHRenderable> result = [self.renderer findRenderableObject:transformedPoint];
	return result;
}

-(void) setRenderer:(SVGRenderer *) newRenderer
{
	if(newRenderer != _renderer)
	{
		_renderer = newRenderer;
		[self setNeedsDisplay];
	}
}

-(void) setDefaultColor:(UIColor *)defaultColor
{
    if(defaultColor != _defaultColor && (_defaultColor == nil || defaultColor == nil || ![_defaultColor isEqual:defaultColor]))
    {
        _defaultColor = defaultColor;
        [self setNeedsDisplay];
    }
    else
    {
        _defaultColor = defaultColor;
    }
}

- (void)drawInContext:(CGContextRef)quartzContext
{
	CGRect	myBounds = self.bounds;
	
	if(!CGRectEqualToRect(myBounds, CGRectZero))
	{
		CGRect drawRect = [self makeDrawingRect];
		CGRect	preferredRect = self.renderer.viewRect;
        if(CGRectIsEmpty(preferredRect))
        {
            preferredRect = drawRect;
        }
		CGFloat	nativeWidth = preferredRect.size.width;
		CGFloat	widthScale = drawRect.size.width/nativeWidth;
		
		
		CGFloat	nativeHeight = preferredRect.size.height;
		CGFloat	heightScale = drawRect.size.height/nativeHeight;
        
        
        NSString*	fillColor = [self.renderer.attributes objectForKey:@"viewport-fill"];
		CGContextSaveGState(quartzContext);
		
        if(!CGRectEqualToRect(drawRect, preferredRect))
        {
            if(self.beTransparent)
            {
                if(self.backgroundColor == 0)
                {
                    CGContextClearRect(quartzContext, myBounds);
                }
                else
                {
                    CGContextSetFillColorWithColor(quartzContext, self.backgroundColor);
                    CGContextFillRect(quartzContext, myBounds);
                }
            }
            else
            {
                if([fillColor isEqualToString:@"none"])
                {
                    CGContextClearRect(quartzContext, myBounds);
                }
                else  if(fillColor != nil)
                {
                    UIColor*	theColor = UIColorFromSVGColorString(fillColor);
                    CGContextSetFillColorWithColor(quartzContext, theColor.CGColor);
                    CGContextFillRect(quartzContext, myBounds);
                }
                else
                {
                    CGColorRef myBackgroundColor = self.backgroundColor;
                    if(myBackgroundColor == 0 && [self.delegate respondsToSelector:@selector(copyFillColor)])
                    {
                        id<FillColorProtocol> fillColorSource = (id<FillColorProtocol>)self.delegate;
                        UIColor* delegatesColor = fillColorSource.copyFillColor;
                        myBackgroundColor = delegatesColor.CGColor;
                        CGColorRetain(myBackgroundColor);
                    }
                    else if(myBackgroundColor != 0)
                    {
                        CGColorRetain(myBackgroundColor);
                    }
                    if(myBackgroundColor == 0)
                    {
                        UIColor*	theColor = UIColorFromSVGColorString(@"white");
                        CGContextSetFillColorWithColor(quartzContext, theColor.CGColor);
                        CGContextFillRect(quartzContext, myBounds);
                    }
                    else if(CGColorGetAlpha(myBackgroundColor) == 0)
                    {
                        CGContextClearRect(quartzContext, myBounds);
                        CGColorRelease(myBackgroundColor);
                    }
                    else
                    {
                        CGContextSetFillColorWithColor(quartzContext, myBackgroundColor);
                        CGContextFillRect(quartzContext, myBounds);
                        CGColorRelease(myBackgroundColor);
                    }
                }
            }
        }

        
		
		CGContextTranslateCTM(quartzContext, drawRect.origin.x, drawRect.origin.y);
		CGContextScaleCTM(quartzContext,widthScale,heightScale);
        CGContextTranslateCTM(quartzContext, -preferredRect.origin.x, -preferredRect.origin.y);
		
		if(fillColor != nil && ![fillColor isEqualToString:@"none"])
		{
			UIColor*	theColor = UIColorFromSVGColorString(fillColor);
			if(theColor != nil)
			{
				CGContextSaveGState(quartzContext);
				CGContextSetFillColorWithColor(quartzContext, theColor.CGColor);
				CGContextFillRect(quartzContext, preferredRect);
				CGContextRestoreGState(quartzContext);
			}
		}
        UIColor* startColor = self.renderer.currentColor;
        if(self.defaultColor != nil)
        {
            self.renderer.currentColor = self.defaultColor;
        }
        
		[self.renderer renderIntoContext:quartzContext];
        self.renderer.currentColor = startColor;
		CGContextRestoreGState(quartzContext);
	}
}
@end

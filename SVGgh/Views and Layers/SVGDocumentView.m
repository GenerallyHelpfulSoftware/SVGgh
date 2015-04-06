//
//  SVGDocumentView.m
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


#import "SVGDocumentView.h"
#import "SVGRendererLayer.h"
@interface SVGDocumentView (Private)
-(SVGRendererLayer*)renderingLayer;
@end

@implementation SVGDocumentView(Private)

-(SVGRendererLayer*)renderingLayer
{
	SVGRendererLayer*	result = (SVGRendererLayer*)self.layer;
	return result;
}

@end

@implementation SVGDocumentView
+ (Class)layerClass
{
	Class	result = [SVGRendererLayer class];
	return result;
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint
{
	id<GHRenderable> result = [[self renderingLayer] findRenderableObject:testPoint];
	return result;
}

-(void) setDefaultColor:(UIColor *)defaultColor
{
    _defaultColor = defaultColor;
    [self renderingLayer].defaultColor = defaultColor;
}

-(void) setRenderer:(SVGRenderer *)newRenderer
{
	[self renderingLayer].renderer = newRenderer;
}

-(SVGRenderer *) renderer
{
	return [self renderingLayer].renderer;
}

-(void) setBeTransparent:(BOOL)beTransparent
{
    [self renderingLayer].beTransparent = beTransparent;
}

-(BOOL) beTransparent
{
    return [self renderingLayer].beTransparent;
}

-(void) setArtworkPath:(NSString *)artworkPath
{
    _artworkPath = artworkPath;
    if(artworkPath.length)
    {
        NSBundle* myBundle = [NSBundle bundleForClass:[self class]];
        NSURL*  myArtwork = [myBundle URLForResource:self.artworkPath withExtension:@"svg"];
        if(myArtwork != nil)
        {
            SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
            self.renderer = renderer;
        }
    }
}

-(UIColor*)copyFillColor
{
    UIColor* result = self.backgroundColor;
    return result;
}

-(void)drawRect:(CGRect)rect
{ // do not remove this unless you like to lose Retina graphics
}

+(void)makeSureLoaded
{
}

@end

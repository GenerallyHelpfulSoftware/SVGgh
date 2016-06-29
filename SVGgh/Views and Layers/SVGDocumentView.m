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
#import "GHControlFactory.h" // for findInterfaceBuilderArtwork
#import "SVGghLoader.h"

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
    [self setArtworkPath:artworkPath fromBundle:nil];
}

+(NSString*) placeHolderSVG
{
    NSString* result = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><svg viewport-fill=\"none\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"  xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" viewBox=\"0, 0, 512, 512\"><rect width=\"510\" fill=\"none\" height=\"510\" stroke=\"#66CDAA\" x=\"1\" y=\"1\" stroke-width=\"2\" vector-effect=\"non-scaling-stroke\" /><path  d=\"M 5 50 27.5 11.03 72.5 11.03 95 50 72.5 88.97 27.5 88.97 5 50z\" transform=\"matrix(2 1.18309 -1.18309 2.05521 86.4456 -29.0634)\" stroke=\"currentColor\" vector-effect=\"non-scaling-stroke\" stroke-width=\"2\"  fill=\"#66CDAA\"/><path d=\"M 5 5 H 95 V 95 H 5 V 5 Z\" transform=\"matrix(2 0 0 2 294 286)\" fill=\"#66CDAA\" stroke=\"currentColor\" vector-effect=\"non-scaling-stroke\" stroke-width=\"2\"  /><path d=\"M 50 5 L 95 95 L 5 95 50 5Z\" transform=\"matrix(2 0 0 2 26 288)\" fill=\"currentColor\" /><path d=\"M50 95A45 45 0 1 1 50.1 95Z M50 85 A35 35 0 1 0 49 85Z\" transform=\"matrix(2 0.5 -0.5 2 313 4)\" fill=\"currentColor\"/></svg>";
    
    return result;
}

+(NSString*) missingArtworkplaceHolderSVG
{
    NSString* result = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" x=\"0px\" height=\"100\" viewport-fill=\"white\" y=\"0px\" width=\"100\" version=\"1.1\" viewBox=\"0 , 0, 100, 100\"> <defs><path d=\"M20 50 A30 30 0 1 1 80 50 A 30 30 0 1 1 20 50Z\" id=\"CIRCLE_TEXT_PATH\" fill=\"none\" stroke=\"none\"/> </defs><g/><g stroke=\"green\" stroke-width=\"1\" vector-effect=\"non-scaling-stroke\" fill=\"#cfdcdd\" stroke-linecap=\"round\"> <path d=\"M0 0H100V100H0ZM50 0A50 50 0 1 0 50 100 50 50 0 1 0 50 0ZM50 25A25 25 0 1 1 50 75 25 25 0 1 1 50 25Z\"/> </g> <text stroke=\"none\" font-size=\"17\" font-family=\"Georgia\" fill=\"#5BB\" color=\"#228B22\"> <textPath xlink:href=\"#CIRCLE_TEXT_PATH\">Enter artworkPath</textPath> </text> <text x=\"50\" y=\"65\" text-anchor=\"middle\" font-family=\"Helvetica\" font-size=\"44\" fill=\"#5BB\">?</text> </svg>";
    
    return result;
}

- (void)prepareForInterfaceBuilder // show a placeholder in Interface Builder
{
    [super prepareForInterfaceBuilder];
    if(self.renderer == nil)
    {
        if(self.artworkPath.length)
        {
            self.renderer = [[SVGRenderer alloc] initWithString:[SVGDocumentView placeHolderSVG]];

        }
        else
        {
            self.renderer = [[SVGRenderer alloc] initWithString:[SVGDocumentView missingArtworkplaceHolderSVG]];
        }
    }
}

-(void) setArtworkPath:(NSString *)artworkPath fromBundle:(NSBundle *)originalBundle {
    _artworkPath = artworkPath;
    
#if TARGET_INTERFACE_BUILDER
    
#else
    
    if(artworkPath.length)
    {
        SVGRenderer* renderer = nil;
        
        NSBundle* myBundle = originalBundle ?: [NSBundle mainBundle];
        renderer = [[SVGghLoaderManager loader] loadRenderForSVGIdentifier:artworkPath inBundle:myBundle];
        if(renderer != nil)
        {
            self.renderer = renderer;
        }
#if TARGET_IPHONE_SIMULATOR
        else
        {
            [self prepareForInterfaceBuilder];
        }
#endif
    }
#endif
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

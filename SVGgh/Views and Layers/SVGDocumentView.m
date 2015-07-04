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
    NSString* result = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <svg xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" x=\"0px\" height=\"100\" viewport-fill=\"white\" y=\"0px\" width=\"100\" version=\"1.1\" viewBox=\"0 , 0, 100, 100\"> <defs><path d=\"M20 50 A30 30 0 1 1 80 50 A 30 30 0 1 1 20 50Z\" id=\"CIRCLE_TEXT_PATH\" fill=\"none\" stroke=\"none\"/> </defs><g/><g stroke=\"green\" stroke-width=\"1\" vector-effect=\"non-scaling-stroke\" fill=\"#cfdcdd\" stroke-linecap=\"round\"> <path d=\"M0 0H100V100H0ZM50 0A50 50 0 1 0 50 100 50 50 0 1 0 50 0ZM50 25A25 25 0 1 1 50 75 25 25 0 1 1 50 25Z\"/> </g> <text stroke=\"none\" font-size=\"17\" font-family=\"Georgia\" fill=\"#5BB\" color=\"#228B22\"> <textPath xlink:href=\"#CIRCLE_TEXT_PATH\">Enter artworkPath</textPath> </text> <text x=\"50\" y=\"65\" text-anchor=\"middle\" font-family=\"Helvetica\" font-size=\"44\" fill=\"#5BB\">?</text> </svg>";
    
    return result;
}

- (void)prepareForInterfaceBuilder // show a placeholder in Interface Builder
{
    if(self.renderer == nil)
    {
        SVGRenderer* renderer = [[SVGRenderer alloc] initWithString:[SVGDocumentView placeHolderSVG]];
        self.renderer = renderer;
    }
}

-(void) setArtworkPath:(NSString *)artworkPath fromBundle:(NSBundle *)originalBundle {
    _artworkPath = artworkPath;
    
    if(artworkPath.length)
    {
        NSBundle* myBundle = originalBundle ?: [NSBundle mainBundle];
        NSURL*  myArtwork = [myBundle URLForResource:self.artworkPath withExtension:@"svg"];
        
#if TARGET_INTERFACE_BUILDER
        if(myArtwork == nil)
        {
            myArtwork = [GHControlFactory findInterfaceBuilderArtwork:artworkPath];
        }
#endif
        if(myArtwork != nil)
        {
            SVGRenderer* renderer = [[SVGRenderer alloc] initWithContentsOfURL:myArtwork];
            self.renderer = renderer;
        }
#if TARGET_IPHONE_SIMULATOR
        else
        {
            [self prepareForInterfaceBuilder];
        }
#endif
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

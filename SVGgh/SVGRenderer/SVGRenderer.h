//
//  SVGRenderer.h
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
//  Created by Glenn Howes on 1/12/11.

#import <Foundation/Foundation.h>
#import "SVGParser.h"
#import "GHRenderable.h"

/*! @brief a class capable of rendering itself into a core graphics context
*/
@interface SVGRenderer : SVGParser<SVGContext, GHRenderable>
/*! @property viewRect
* @brief the intrinsic rect declared in the SVG document being rendered
*/
@property (nonatomic, readonly)         CGRect	viewRect;

/*! @brief a queue where it is convenient to renders when the main queue is not necessary
* @return a shared operation queue
*/
+(NSOperationQueue*) rendererQueue;

/*! @brief draw the SVG
* @param quartzContext context into which to draw, cold be a CALayer, a PDF, an offscreen bitmap, whatever
*/
-(void)renderIntoContext:(CGContextRef)quartzContext;

/*! @brief try to locate an object that's been tapped
* @param testPoint a point in the coordinate system of this renderer
* @return an object which implements the GHRenderable protocol
*/
-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint;

@end





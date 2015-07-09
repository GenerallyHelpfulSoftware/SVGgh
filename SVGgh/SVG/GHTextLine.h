//
//  GHTextLine.h
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2013-2014 Glenn R. Howes

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
//  Created by Glenn Howes on 2/6/13.


#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreText;
#else
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#endif

#import "GHAttributedObject.h"
#import "GHPathDescription.h"
#import "GHGlyph.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief manifestation of an SVG 'tspan' entity a collection of other entities
 */
@interface GHTextLine : GHAttributedObject<GHPathDescription, GHGlyphMaker>
/*! @brief init method that takes a a CTLineRef
*/
-(instancetype) initWithAttributes:(NSDictionary *)theAttributes andTextLine:(CTLineRef)lineRef;


/*! @brief return a tight bounding box for the object's content
 * @param svgContext state information about the document environment
 */
-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext;
@end

NS_ASSUME_NONNULL_END

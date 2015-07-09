//
//  GHGlyph.h
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
//  Created by Glenn Howes on 2/3/13.

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreText;
#else
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#endif

#import "GHAttributedObject.h"
#import "GHPathDescription.h"
#import "SVGUtilities.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief A protocol for an object capable of creating GHGlyphs or adding them to a CGContextRef.
*/
@protocol GHGlyphMaker <NSObject>

/*! @brief Add glyphs to an array being built up of GHGlyphs.
 * @param glyphList array to add GHGlyph objects to
 * @param svgContext svg state information at this point of the render
 @ @see GHGlyph
 */
-(void)addGlyphsToArray:(NSMutableArray*)glyphList  withSVGContext:(id<SVGContext>)svgContext;

/*! @brief Draw individually positioned glyphs to the context.
* @param quartzContext context to draw into
* @param svgContext svg state information at this point of the render
*/
-(void)addGlyphsToContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext;


/*! @brief Draw the glyphs to the context (draw more as lines than individually positioned glyphs).
 * @param quartzContext context to draw into
 * @param theContext svg state information at this point of the render
 */
-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)theContext;

/*! @brief Render the glyphs into a path.
* @return a path. Caller responsible for disposal.
*/
-(CGPathRef) newPath;
@end

/*! @brief a class which wraps the CGGlyph object, and allows for individualy positioning glyphs
*/
@interface GHGlyph : GHAttributedObject<GHPathDescription>
@property(nonatomic, readonly)      CTFontRef           font;
@property(nonatomic, readonly)      CGGlyph             glyph;
@property(nonatomic, readonly)      NSDictionary*       textAttributes;
@property(nonatomic, readonly)      CGPoint             offset;
@property(nonatomic, readonly)      CGPoint             renderPoint;
@property(nonatomic, readonly)      CGFloat             rotationAngleInRadians;
@property(nonatomic, readonly)      CGFloat             width;
@property(nonatomic, readonly)      CGRect              runRect; // rect within a run
@property(nonatomic, readonly)      BOOL                notRendering; // wasn't able to lay this out
@property (nonatomic, readonly)     CGAffineTransform	transform;

/*! @property boundingBox
* @see CTFontGetBoundingRectsForGlyphs
*/
@property(nonatomic, readonly)      CGRect              boundingBox;

/*! @brief Routine which attempts to take an array of GHGlyphs and place them along a path.
* @attention algorithm could definitely be improved.
* @param listOfGlyphs array of GHGlyphs that need to be positioned
* @param aPath a Core Graphics path along which to position the baselines of the GHGlyphs
*/
+(void) positionGlyphs:(NSArray*)listOfGlyphs alongCGPath:(CGPathRef)aPath;

/*! @brief Given a list of GHGlyphs that have already been positioned. Figure out their bounding box.
* @param listOfGlyphs pre-positioned GHGlyphs.
*/
+(CGRect)rectForGlyphs:(NSArray*)listOfGlyphs; // glyphs should be prepositioned

/*! @brief the init method you should call lots of parameters
* @param theAttributes the parent entity's SVG attributes
* @param textAttributes Core Text attributes appropriate for describing fonts. See SVGTextUtilities.h 
* @param aFont base font to use
* @param aGlyph the Core Graphics glyph we are wrapping
* @param aTransform a transform for positioning and scaling
* @param offset offset along a line
* @param theWidth pre-calculated width of the glyph
* @see coreTextAttributesFromSVGStyleAttributes:
*/
-(instancetype) initWithDictionary:(NSDictionary *)theAttributes textAttributes:(NSDictionary*) textAttributes font:(CTFontRef)aFont glyph:(CGGlyph)aGlyph transform:(CGAffineTransform)aTransform offset:(CGPoint)offset runBox:(CGRect)runRect andWidth:(CGFloat)theWidth;

/*! @brief not allowing a standard init method
*/
-(nullable instancetype) init __attribute__((unavailable("init not available")));

/*! @brief Asks the question for hit testing.
* @param aPoint a point in the same coordinate system as this glyph
* @return YES if the point is in the bounds of this glyph
 */
-(BOOL) isPointInBoundingBox:(CGPoint)aPoint;

/*! @brief Adding a path (but not drawing).
* @param quartzContext a Core Graphics context to add this glyph's path to.
* @param svgContext a drawing state context for extra information
*/
-(void) addPathToContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>) svgContext;
@end

NS_ASSUME_NONNULL_END

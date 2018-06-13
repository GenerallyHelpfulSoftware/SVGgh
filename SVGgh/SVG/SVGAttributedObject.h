//
//  SVGAttributedObject.h
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
//  Created by Glenn Howes on 1/25/14.

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import "GHAttributedObject.h"
#import "SVGUtilities.h"
#import "GHAttributedObject.h"
#import "GHRenderable.h"
#import "GHCSSStyle.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief base object for objects defined in an SVG document
*/
@interface SVGAttributedObject : GHAttributedObject
/*! @brief answers the question if this particular object should be rendered. Might be hidden or not be visible in the user's language settings.
* @param svgContext state information needed to make this decision
* @return YES if object should be drawn
*/
-(BOOL)environmentOKWithSVGContext:(id<SVGContext>)svgContext;

/*! @brief answers the question if this particular object should be rendered given the user's language settings.
 * @param isoLanguage something like 'en', 'zh' 
 * @return YES if object should be drawn
 */
-(BOOL)environmentOKWithISOCode:(NSString*)isoLanguage;

/*! @brief is this object hidden during drawing, i.e. attribute 'display' is set to 'none'
* @return YES if it's not to be rendered
*/
-(BOOL) hidden;
@end


/*! @brief abstract class whose concrete versions are used to fill shapes, e.g. solid colors and gradients
*/
@interface GHFill : SVGAttributedObject
@end

/*! @brief an object that can figure out what color to use given the current context
*/
@interface GHSolidColor : GHFill
/*! @brief finds a color either in this object or if it's the currentColor from the svgContext
* @param svgContext the state in which this object finds itself called
* @return the found color as a UIColor*
*/
-(nullable UIColor*) asColorWithSVGContext:(id<SVGContext>)svgContext;
@end

/*! @brief an abstract object which implements the GHRenderable protocol
* @see GHRenderable
*/
@interface GHRenderableObject : SVGAttributedObject<GHRenderable>
/*! @property fillColor the color to use for filling
*/
@property (copy, nonatomic) 	UIColor* __nullable 		fillColor;
/*! @property defaultFillColor if the fillColor isn't explicitly set, this is what be used (typically black)
*/
@property (copy, nonatomic, readonly)  NSString*                  defaultFillColor;

/*! @property transform 
* @brief every renderable object can have its own transform which scales, translates, rotates or skews
*/
@property (nonatomic, assign)   CGAffineTransform transform;

/*! @brief setup the drawing environment based on the provided SVG attributes
* @param quartzContext Core Graphics to setup properties such as line width, line joins, etc.
* @param attributes a collection of attributes
* @param svgContext a state object needed to retrieve some properties not explicitly set in the provided attributes
*/
+(void) setupContext:(CGContextRef)quartzContext withAttributes:(nullable NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext;

/*! @brief retrieve a bounding box for an object. As sometimes an objects bounds are given in terms of its parent, provided the parent bounds
* @param anObject object to test
* @param svgContext a state object needed to retrieve some properties not explicitly set in the provided attributes
* @param parentBounds needed as sometimes objects are sized in reference to their containing object
*/
+(CGRect) boundingBoxForRenderableObject:(id<GHRenderable>)anObject withSVGContext:(id<SVGContext>) svgContext givenParentObjectsBounds:(CGRect)parentBounds;

/*! @brief see if this object contains the given point
* @param testPoint point to check
* @return YES if the object was hit (and not a hole inside the object)
*/
-(BOOL)	hitTest:(CGPoint) testPoint;

/*! @brief a style attribute might have to be extracted from a 'style' attribute which can and usually will contain multiple attributes bundled together
* @param attributeName attribute to search for in this object's attributes
* @return the value of the attribute if it exists
*/
-(nullable NSString*) valueForStyleAttribute:(NSString*)attributeName   withSVGContext:(nullable id<SVGContext> )svgContext;

/*! @brief sometimes objects are referenced internally in a document by name, this adds them to a map to keep track of
* @param namedObjectsMap a collection of objects to add
*/
-(void) addNamedObjects:(NSMutableDictionary*)namedObjectsMap;
@end

/*! @brief an encapsulation of a bitmap or other static image
*/
@interface GHImage : GHRenderableObject
/*! @brief given a set of attributes create a new image presumabley this will be from an SVG 'image' entity
* @param theAttributes appropriate attributes for an SVG 'image'
* @return a renderable object (probably a GHImage*)
*/
+(nullable id<GHRenderable>)newImageWithDictionary:(NSDictionary*)theAttributes;
@end

/*! @brief an abstract class whose concrete subclasses will be wrappers for CGPathRefs
* @see CGPathRef
*/
@interface GHShape : GHRenderableObject
@property (nonatomic, readonly)         BOOL			isClosed;
@property (nonatomic, readonly)         BOOL            isFillable;
@property (nonatomic, readonly)          CGPathRef	__nullable	quartzPath;
@end

/*! @brief manifestation of an SVG 'ellipse' entity
 */
@interface GHEllipse : GHShape
@end

/*! @brief manifestation of an SVG 'rect' entity
 */
@interface GHRectangle : GHShape
@end

/*! @brief manifestation of an SVG 'circle' entity
 */
@interface GHCircle : GHEllipse
@end

/*! @brief manifestation of an SVG 'line' entity
 */
@interface GHLine : GHShape
@end

/*! @brief manifestation of an SVG 'path' entity
 */
@interface GHPath : GHShape
/*! @property renderingPath the 'd' attribute of the 'path' entitity
*/
@property(weak, nonatomic, readonly) NSString* __nullable renderingPath;
@end

/*! @brief manifestation of an SVG 'polyline' entity
 */
@interface GHPolyline : GHPath
@end

/*! @brief manifestation of an SVG 'polygon' entity
 */
@interface GHPolygon : GHPath
@end

/*! @brief manifestation of an SVG 'g' entity a collection of other entities
 */
@interface GHShapeGroup : SVGAttributedObject<GHRenderable>
/*! @property children a collection of SVGAttributedObject that are beneath this object in the document's hierarchy
*/
@property (copy, nonatomic, readonly)	NSArray* __nullable 	children;
/*! @property childDefinitions a list of NSDictionarys' which can be used to create the children of this group. The intermediate form.
*/
@property (copy, nonatomic)  NSArray* __nullable  childDefinitions;

-(void) addNamedObjects:(NSMutableDictionary*)namedObjectsMap;
@end

/*! @brief manifestation of an SVG 'switch' entity which allows decisions to be made about what to draw
 */
@interface GHSwitchGroup : GHShapeGroup

@end

/*! @brief manifestation of an SVG 'defs' entity which is a repository of shared entity definitions to encourage reuse
 */
@interface GHDefinitionGroup : GHShapeGroup

@end

/*! @brief manifestation of an SVG 'style' entity which is a way to bridge with css formatting.
 */
@interface GHStyle : SVGAttributedObject
@property (nonatomic, readonly)  StyleElementType styleType;
@property(nonatomic, readonly) NSDictionary<NSString*, GHCSSStyle*>* classes;
@end

/*! @brief manifestation of an SVG 'clipPath' entity
 */
@interface GHClipGroup : GHShapeGroup
+(nullable instancetype)clipObjectForAttributes:(NSDictionary*)attributes withSVGContext:(id<SVGContext>)svgContext;
@end
/*! @brief manifestation of an SVG 'mask' entity
 */
@interface GHMask : GHClipGroup
@end

/*! @brief manifestation of an SVG 'use' entity which allows an object defined elsewhere in the document to be used in this place
 */
@interface GHRenderableObjectPlaceholder : GHRenderableObject
-(nullable GHRenderableObject*)  concreteObjectForSVGContext:(id<SVGContext>)svgContext excludingPrevious:(nullable NSMutableSet*)setToAvoidLoops;
@end

NS_ASSUME_NONNULL_END

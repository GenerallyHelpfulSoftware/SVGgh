//
//  SVGUtilities.h
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
//  Created by Glenn Howes on 1/11/13.
//

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif


#import "GHImageCache.h"
#import "SVGContext.h"

NS_ASSUME_NONNULL_BEGIN

/*!
*    @brief callback called to ask if a given attribute with a given key should be replaced by a given replacement
*   @see SVGMergeStyleAttributes
*/
typedef BOOL (^attribute_replacement_filter_t)(NSString*  key, __nullable id sourceAttribute, __nullable id destAttribute);


/*! \brief utility routine which takes a string and converts it to a CGRect
 * \param serializedRect a string of the form 'x, y, width, height'
 * \return an appropriate rectangle
 */
CGRect SVGStringToRect( NSString*  serializedRect);
CGRect SVGStringToRectSlow( NSString*  serializedRect);

/*! \brief utility routine which takes a string and converts it to a UIColor
* \param stringToConvert such as @"blue", 3 char hex like @"#A7A", 6 char hex like @"#FF77C0", or rgb like @"rgb(0,255,127)"
* \return a color with an RGB color space
*/
 UIColor* __nullable  UIColorFromSVGColorString ( NSString *  stringToConvert);


/*! \brief utility routine which transitions from one color to another
 * \param oldSVGColorString an SVG color string (fractionThere at 0)
 * \param newSVGColorString (fractionThere at 1)
 * \param fractionThere a number between 0 and 1 indicating relative weight to the color strings
 * \return a string expressing a color
 */
 NSString*  MorphColorString( NSString*  oldSVGColorString,  NSString*  newSVGColorString, CGFloat fractionThere);

/*! \brief utitlity routine to convert an SVG string representing a set of affine transform operations to the resulting CGAffineTransform
 * \param transformAttribute a string like 'scale(10,20), translate(22, 0), rotate(.5)'
 * \return an affine transform
 * \see CGAffineTransform
 */
CGAffineTransform SVGTransformToCGAffineTransform( NSString*  transformAttribute);

/*! \brief utility routine which transitions from one affine transform to another (like moving an object across the view)
 * \param oldtransform an SVG transform string (fractionThere at 0)
 * \param newTransform (fractionThere at 1)
 * \param fractionThere a number between 0 and 1 indicating relative weight to the transform strings
 * \return a string expressing a transform in matrix form
 */
 NSString*  SVGTransformMorph( NSString*  oldtransform,  NSString*  newTransform, CGFloat fractionThere);
CGAffineTransform SVGTransformToCGAffineTransformSlow( NSString*  transformAttribute);// older better tested version

/*! \brief serialize an affine transform back to an SVG style string version of a transform (probably in matrix form)
* \param aTransform Core Graphics affine transform
* \return a string appropriate for an SVG entities 'transform' attribute
*/
 NSString*  CGAffineTransformToSVGTransform(CGAffineTransform aTransform);

/*! \brief utility routine to take one set of entity attributes and try to determine intermediate values for appropriate ones
* \param oldAttributes set of attributes in the beginning (fractionThere at 0)
* \param newAttributes set of attributes at the end of the transition (fractionThere at 1)
* \param fractionThere a number between 0 and 1 indicating relative weight to the beginning and ending attributes
* \return an intermediate dictionary of attributes
*/
 NSDictionary*  SVGMorphStyleAttributes( NSDictionary* oldAttributes,  NSDictionary*  newAttributes, CGFloat fractionThere);

/*! \brief a routine to allocate an offscreen bitmap drawing context
* \param pixelsWide width of the bitmap
* \param pixelsHigh height of the bitmap
* \return a Core Graphics context to draw into caller responsible for deallocation
*/
__nullable CGContextRef BitmapContextCreate (size_t pixelsWide, size_t pixelsHigh) CF_RETURNS_RETAINED;

/*! \brief some SVG attribues are of the form of a list, such as the fallback list of fonts as in 'Times, Georgia, san-serif'
* \param svgAttributes dictionary to search for the key
* \param key an attribute name like 'font-weight' which might be the key to a list of alternative values
* \return an array of acceptable alternatives in order of preference
*/
 NSArray* __nullable  ArrayForSVGAttribute( NSDictionary*  svgAttributes,  NSString*  key);

/*! \brief the root element of an SVG document assumes certain default attributes it doesn't have to explicitly provide. This provides them
* \return a dictionary of attributes to be used if not provided by the root svg entity
*/
 NSDictionary*  DefaultSVGDrawingAttributes(void);

/*! an SVG path entity has a set of attributes it accepts. This returns them
* \return a set of attributes like 'stroke-dashoffset' or 'fill'
*/
 NSSet*  StandardPathAttributes(void);

/*! \brief given a set of attributes, build a new set by selectiving merging in attributes from a superceding set
* \param parentAttributes the starting attributes from higher up in the document
* \param attributesToMergeIn attributes which should supercede (probably) the values in the parentAttributes
* \param filter callback block which allows the calling routine to selectively do this merging
* \return a dictionary of attributes which is the result of the merger
*/
 NSDictionary*  SVGMergeStyleAttributes( NSDictionary*  parentAttributes,  NSDictionary*  attributesToMergeIn, __nullable attribute_replacement_filter_t filter);

/*! \brief Answer the question is the input string of the form 'URL(#nameOfEntity)'
* \param aString some string that might be of the right form
* \return YES if it does appear to be of that form
*/
BOOL IsStringURL( NSString*  aString); // has URL prefix

/*! \brief utitlity routine to strip out the URL function boilerplate around an internal URL reference
* \param aString a string of the form 'URL(#nameOfEntity)'
* \return 'nameOfEntity'
*/
 NSString* __nullable  ExtractURLContents( NSString*  aString);

/*! \brief sometimes instead of having attributes in individual XML attributes, they are bundled up in 1 single attribute as in the 'style' attribute
* \param compactedAttributes a string of colon and semi-colon separated components such as 'stroke-width:8;fill:black;stroke-linecap:round;stroke:purple' 
*\return dictionary with these extracted into individual attributes
*/
 NSDictionary* __nullable  AttributesFromSVGCompactAttributes( NSString*  compactedAttributes);

/*! \brief remove the " character
* \param possiblyQuotedString string with SVG quoting in it
* \return input string shorn of quotes
*/
 NSString* __nullable  UnquotedSVGString( NSString*  possiblyQuotedString);

/*! \brief given two vectors, caclculate the angle
* \param vector1 a vector
* \param vector2 a vector
* \return an angle in radians
*/
CGFloat CalculateVectorAngle(CGPoint	vector1, CGPoint vector2);
/*! \brief given the parameters SVG provides for an arc operation inside a path entity, add the arc to the path
 * \param thePath a core graphics mutable path
 * \param xRadius how wide is the arc
 * \param yRadius how high is the arc
 * \param xAxisRotationDegrees how titled is the x-axis off of the nominal x-axis
 * \param largeArcFlag will this arc follow the longest (YES) or the shortest (NO) way around the arc to the ending
 * \param sweepFlag does this go clockwise (YES)
 * \param endPointX where does this arc terminate x
 * \param endPointY where does this arc terminate y
 */
void AddSVGArcToPath(CGMutablePathRef thePath,
                     CGFloat xRadius,
                     CGFloat  yRadius,
                     double  xAxisRotationDegrees,
                     BOOL largeArcFlag, BOOL	sweepFlag,
                     CGFloat endPointX, CGFloat endPointY);

/*! \brief generate an SVG arc operation given what a sane person would use to specify an arc
 * \param xRadius how wide is the arc
 * \param yRadius how high is the arc
 * \param xAxisRotationDegrees how titled is the x-axis off of the nominal x-axis
 * \param startAngle where should it start (degrees)
 * \param endAngle where should it end (degrees)
*/
 NSString*  SVGArcFromSensibleParameters(CGFloat xRadius, CGFloat yRadius, double xAxisRotationDegrees,
                                         double startAngle, double endAngle);

extern const CGFloat kDegreesToRadiansConstant;
extern  NSString*  const	kWhiteInHex;
extern  NSString*  const   kBlackInHex;
extern const CGColorRenderingIntent	kColoringRenderingIntent;


/*! @brief a class with no instances that just has some functional utitity methods
*/
@interface SVGToQuartz : NSObject

/*! @brief utility to dump the state of a quartz context to the debugging output. 
* @attention feel free to log this from XCode's debugger console if you happen to have a Core Graphics context handy. 
* @attention (lldb) call (void) [SVGToQuartz LogQuartzContextState:quartzContext];
*/
+(void) LogQuartzContextState:(CGContextRef)quartzContext;

/*! @brief does the given dictionary of attributes does one of them have the 'display' attribute set to 'none'. i.e. is the element invisible?
* @param attributes an entities elements to check
* @return YES if the attributes indicate hiding is in order
*/
+(BOOL)attributeHasDisplaySetToNone:(NSDictionary*)attributes;

/*! @brief try to find the value for a style attribute inside a dictionary of attributes. Might be free-standing or in a 'style' attribute
* @param attributeName which style type attribute are we looking for?
* @param elementAttributes attributes to look inside
* @return the value if it is found
*/
+(nullable NSString*) valueForStyleAttribute:(NSString*)attributeName fromDefinition:(NSDictionary*)elementAttributes;

/*! @brief try to find the value for a style attribute inside a dictionary of attributes. Might be free-standing or in a 'style' attribute
 * @param attributeName which style type attribute are we looking for?
 * @param elementAttributes attributes to look inside
 * @param entityTypeName name to look into the 'style' entity for CSS attributes
 * @parm svgContext context to retrieve CSS based attributes
 * @return the value if it is found
 */
+(nullable NSString*) valueForStyleAttribute:(NSString*)attributeName fromDefinition:(NSDictionary*)elementAttributes forEnityName:(NSString* __nullable)entityTypeName withSVGContext:(id<SVGContext> __nullable)svgContext;

/*! @brief given a composite style attribute, break it apart into individual attributes
* @param styleString a string with potentially many attributes encoded into it.
* @return a dictionary of the individual attributes
* @see AttributesFromSVGCompactAttributes
*/
+(NSDictionary*  )dictionaryForStyleAttributeString:(NSString* )styleString;
/*! @brief take a bunch of individual attributes and package them up in a single 'style' type string
* @param styleDictionary a bunch of style attributes that can be compacted up
* @return a compact version of style attributes where they are all jammed together in one string
*/
+(NSString*)styleAttributeStringForDictionary:(NSDictionary*)styleDictionary;

/*! @brief given a 'stroke-linejoin' SVG attribute setup the context for drawing with that line join
* @param quartzContext a Core Graphics context
* @param miterString a valid SVG const string for this: 'miter', 'round', 'bevel'
*/
+(void)setupMiterForQuartzContext:(CGContextRef)quartzContext withSVGMiterString:(nullable NSString*)miterString;

/*! @brief given a 'stroke-linecap' SVG attribute setup the context for drawing with that line cap
* @param quartzContext a Core Graphics context
* @param lineCapString a valid SVG const string for this: 'butt', 'round', 'square'
*/
+(void)setupLineEndForQuartzContext:(CGContextRef)quartzContext withSVGLineEndString:(nullable NSString*)lineCapString;

/*! @brief given a 'stroke-miterlimit' SVG attribute setup the context for drawing with that miter limit 
* @attention miter limits involve the behavior of acute intersections of line sections (look it up)
* @param quartzContext a Core Graphics context
* @param miterLimitString a number string setting the miter
* @see CGContextSetMiterLimit
*/
+(void) setupMiterLimitForQuartzContext:(CGContextRef)quartzContext withSVGMiterLimitString:(nullable NSString*)miterLimitString;

/*! @brief given a 'mix-blend-mode' SVG attribute setup the context for drawing with that blend mode
* @param quartzContext a Core Graphics context
* @param blendModeString a valid svg mix-blend-mode value string (eg. 'normal', 'overlay')
* @see CGContextSetBlendMode
*/
+(void)setupBlendModeForQuartzContext:(CGContextRef)quartzContext withBlendModeString:(nullable NSString*)blendModeString;

/*! @brief setup line drawing to use a given dash pattern and phase into that dash pattern
* @param quartzContext a Core Graphics context
* @param strokeDashString a string which can be broken into a series of numbers indicating the alternating black white dash lengths (or 'none')
* @param phaseString a number indicating how far into the pattern to start drawing
* @see CGContextSetLineDash
*/
+(void) setupLineDashForQuartzContext:(CGContextRef)quartzContext withSVGDashArray:(nullable NSString*)strokeDashString andPhase:(nullable NSString*)phaseString;

/*! @brief setup the opacity of future drawing into a context
* @param quartzContext a Core Graphics context
* @param opacityString a number as a string between 0 and 1
* @see CGContextSetAlpha
*/
+(void) setupOpacityForQuartzContext:(CGContextRef)quartzContext withSVGOpacity:(NSString*)opacityString __attribute__((deprecated));; 

+(void) setupOpacityForQuartzContext:(CGContextRef)quartzContext withSVGOpacity:(NSString*)opacityString withSVGContext:(id<SVGContext>)svgContext;

/*! @brief setup the line width for stroking lines. May have a vector effect which results in scale ignoring drawing
* @param quartzContext a Core Graphics context
* @param strokeString a number as a string indicating stroke width, 0 means no drawing. 
* @param vectorEffect may be 'non-scaling-stroke' which means that a line width of 1 will always be 1 point wide on screen.
* @param svgContext this is passed in to allow for some tricks with scaling (rarely done)
*/
+(void) setupLineWidthForQuartzContext:(CGContextRef)quartzContext withSVGStrokeString:(nullable NSString*)strokeString withVectorEffect:(nullable NSString*)vectorEffect withSVGContext:(id<SVGContext>)svgContext;

/*! @brief set the color for drawing with the given color string. Perhaps with some contextual help.
* @param quartzContext a Core Graphics context
* @param colorString some string which can be interpreted by the context to become a UIColor and then setup the drawing enviroment
* @param svgContext needed to answer such questions as what the 'currentColor' is.
*/
+(void) setupColorForQuartzContext:(CGContextRef)quartzContext withColorString:(nullable NSString*)colorString withSVGContext:(id<SVGContext>)svgContext;

/*! @brief bitmap images can be embedded as hex in SVG documents or referenced relatively to the document's URL or file path. This retrieves them
* @param xLinkPath contents of SVG's 'xlink:href' attribute
* @param relativeFilePath contents of SVG's 'xml:base' attribute
* @param svgContext needed to do the location
* @param retrievalCallback callback to get your image back
*/
+(void) imageAtXLinkPath:(nullable NSString*)xLinkPath orAtRelativeFilePath:(nullable NSString*)relativeFilePath withSVGContext:(id<SVGContext>)svgContext intoCallback:(handleRetrievedImage_t)retrievalCallback;

/*! @brief SVG image entities have various modes to draw taking into account their natural aspect ratios and sizes. These modes are selected via the 'preserveAspectRatio' attribute
* @param preserveAspectRatioString a variety of possible selectors here such as 'xMidYMin', 'slice', 'meet' ... See the SVG specification.
* @param viewRect the rectangle you are trying to fit the image into.
* @param naturalSize the intrinsice size of the image in pixels.
*/
+(CGRect) aspectRatioDrawRectFromString:(nullable NSString*)preserveAspectRatioString givenBounds:(CGRect)viewRect
                            naturalSize:(CGSize)naturalSize;
@end


CGFloat	GetNextCoordinate( const char* buffer,  NSUInteger*  indexPtr, NSUInteger bufferLength,  BOOL* failed);
NS_ASSUME_NONNULL_END

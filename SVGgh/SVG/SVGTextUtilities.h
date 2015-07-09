//
//  SVGTextUtilities.h
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
//  Created by Glenn Howes on 2/2/13.
//

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreText;
#else
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/*! @brief collection of class methods appropriate with dealing with Text
*/
@interface SVGTextUtilities : NSObject
/*! @brief method to remove extraneous new lines and white space characters
* @param sourceText text to clean
* @return cleaned text
*/
+(NSString*) cleanXMLText:(NSString*)sourceText;

/*! @brief convert SVG style attributes to Core Text attributes
* @param SVGattributes collection of attributes known to be found in such SVG entities as 'text', 'tspan', 'textArea'
* @return collection of Core Text attributes
*/
+(nullable NSDictionary*) fontAttributesFromSVGAttributes:(NSDictionary*)SVGattributes;

/*! @brief create a CTFontDescriptorRef by creating the best approximation of the requested font
* @param attributes a collection of appropriate SVG text attributes
* @param baseDescriptor a descriptor to act ast the starting point for the font descriptor being created
* @return a configured font descriptor. Caller responsible for disposal.
*/
+(CTFontDescriptorRef)	newFontDescriptorFromAttributes:(NSDictionary*) attributes baseDescriptor:(nullable CTFontDescriptorRef)baseDescriptor;

/*! @brief create a font from a Core Text font descriptor
* @param fontDescriptor a description of what Font we want
* @return a Core Text Font. Caller responsible for disposal.
*/
+(CTFontRef) newFontRefFromFontDescriptor:(CTFontDescriptorRef)fontDescriptor;

/*! @brief convert SVG style text attributes to Core Text style attributes
* @param svgStyle collection of text attributes
* @return a collection of Core Text appropriate attributes
*/
+(nullable NSDictionary*) coreTextAttributesFromSVGStyleAttributes:(NSDictionary*)svgStyle;

/*! @brief convert SVG style text attributes to Core Text style attributes given a Core Text font descriptor as a starting point
* @param svgStyle collection of text attributes
* @param baseDescriptor a starting point for the Core Text attributes we want to generate
* @return a collection of Core Text appropriate attributes
*/
+(nullable NSDictionary*) coreTextAttributesFromSVGStyleAttributes:(NSDictionary*)svgStyle baseDescriptor:(nullable CTFontDescriptorRef)baseDescriptor;

/*! @brief create an attributed string given a string and various font and font descriptor bits of information
* @param text the unattributed text
* @param styleAttributes collection of SVG text attributes
* @param baseFont font that's the starting point for creating the attributed string
* @param baseFontDescriptor font descriptor that is the starting point for creating the attributed string
* @param includeParagraphStyle most text we render don't need Core Text paragraph attributes
*/
+(NSAttributedString*) attributedStringFromString:(NSString*)text SVGStyleAttributes:(NSDictionary*)styleAttributes baseFont:(nullable CTFontRef)baseFont baseFontDescriptor:(nullable CTFontDescriptorRef)baseFontDescriptor includeParagraphStyle:(BOOL)includeParagraphStyle;

/*! @brief create an attributed string given a string and various font and font descriptor bits of information
 * @param text the unattributed text
 * @param nonFontSVGStyleAttributes collection of SVG text attributes unrelated to fonts
 * @param baseFont font that's the starting point for creating the attributed string
 * @param baseFontDescriptor font descriptor that is the starting point for creating the attributed string
 * @param includeParagraphStyle most text we render don't need Core Text paragraph attributes
 */
+(NSAttributedString*) attributedStringFromString:(NSString*)text nonFontSVGStyleAttributes:(nullable NSDictionary*)nonFontSVGStyleAttributes baseFont:(nullable  CTFontRef)baseFont baseFontDescriptor:(nullable CTFontDescriptorRef)baseFontDescriptor  includeParagraphStyle:(BOOL)includeParagraphStyle;

@end

NS_ASSUME_NONNULL_END

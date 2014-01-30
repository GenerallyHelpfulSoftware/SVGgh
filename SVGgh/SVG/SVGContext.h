//
//  SVGContext.h
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
//  Created by Glenn Howes on 1/28/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*! @brief a protocol followed to communicate state when walking through a tree of SVG objects, passed into nodes/leaves in that tree
 */
@protocol SVGContext
/*! @brief makes a color for a given string found in such SVG attributes as fill, stroke, etc..
 * @param svgColorString a string such as 'blue', '#AAA', '#A7A2F9' or 'rgb(122, 255, 0)' which can be mapped to an RGB color
 * @return a UIColor from the RGB color space
 * @see UIColorFromSVGColorString
 */
-(UIColor*) colorForSVGColorString:(NSString*)svgColorString;
/*! @brief make a URL relative to the document being parsed
 * @param subPath a location inside the app's resource bundle
 * @return an NSURL to some resource (hopefully)
 */
-(NSURL*)	relativeURL:(NSString*)subPath;

/*! @brief make a URL
 * @param absolutePath a file path
 * @return an NSURL to some resource (hopefully)
 */
-(NSURL*)   absoluteURL:(NSString*)absolutePath; // sort of...

/*! @brief find an object whose 'id' or maybe 'xml:id' property have the given name
 * @param objectName the name key to look for
 * @return some object (usually an id<GHRenderable> but not always
 */
-(id)       objectNamed:(NSString*)objectName;

/*! @brief sometimes objects in SVG are referenced in the form 'URL(#aRef)'. This returns them.
 * @param aLocation some object in this document probably
 * @return some object (usually an id<GHRenderable> but not always
 */
-(id)       objectAtURL:(NSString*)aLocation;
/*! @brief sometimes SVG colors are specified as 'currentColor'. This sets the starting currentColor before the tree is visited. Good for colorizing artwork.
 * @param startingCurrentColor a UIColor to start with
 */
-(void)     setCurrentColor:(UIColor*)startingCurrentColor;
/*! @brief the value for 'currentColor' at this moment in the process of visiting a document
 */
-(UIColor*) currentColor;
/*! @brief the active language expected by the user like 'en' or 'sp' or 'zh'
 */
-(NSString*) isoLanguage;

/*! @brief if the SVG document specifies a 'non-scaling-stroke' this could be used to scale that. Rarely used.
 */
-(CGFloat)  explicitLineScaling;
@end


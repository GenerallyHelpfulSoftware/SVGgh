//
//  SVGGradientUtilities.h
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
//  Created by Glenn Howes on 2/11/13.
//

#if defined(__has_feature) && __has_feature(modules)
@import Foundation;
@import CoreGraphics;
#else
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/*! @brief a couple of methods of general use
*/
@interface SVGGradientUtilities : NSObject
/*! @brief no need to keep reallocating the color space
*/
+(CGColorSpaceRef) colorSpace;

/*! @brief a method to extract an individual fraction from a gradient entity definition
* @param svgFractionOrPercentage the kind of fraction found in the 'cx', 'cy', etc attributes of a SVG gradient
* @param defaultValue if the attribute wasn't set
* @return the fraction used to define the gradient parameter
*/
+(CGFloat) extractFractionFromCoordinateString:(NSString*)svgFractionOrPercentage givenDefault:(CGFloat)defaultValue;
@end

NS_ASSUME_NONNULL_END

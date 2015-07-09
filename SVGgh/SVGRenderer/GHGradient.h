//
//  GHGradient.h
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2012-2014 Glenn R. Howes

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

#import "SVGAttributedObject.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief An abstract implementation of a GHFill that will add gradients to a properly setup Core Graphics Context
*/
@interface GHGradient : GHFill
/*! @brief Given a Core Graphics context which has a non-empty path set up, fill it with a gradient.
* @param quartzContext Core Graphics context to draw into
* @param svgContext a context capable of providing additional information
* @param objectBox This is needed to know the extent of the object being filled.
*/
-(void) fillPathToContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox;
@end

/*! @brief GHGradient concrete class that uses CGContextDrawLinearGradient
*/
@interface GHLinearGradient : GHGradient
@end

/*! @brief GHGradient concrete class that calls CGContextDrawRadialGradient
*/
@interface GHRadialGradient : GHGradient
@end

NS_ASSUME_NONNULL_END

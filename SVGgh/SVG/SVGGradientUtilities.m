//
//  SVGGradientUtilities.m
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

#import "SVGGradientUtilities.h"

@implementation SVGGradientUtilities
+(CGColorSpaceRef) colorSpace
{
    static CGColorSpaceRef sResult = 0;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = CGColorSpaceCreateDeviceRGB();
    });
    
    
    return sResult;
}

+(CGFloat) extractFractionFromCoordinateString:(NSString*)svgFractionOrPercentage givenDefault:(CGFloat)defaultValue
{
    CGFloat result =defaultValue;
    if([svgFractionOrPercentage hasSuffix:@"%"] || [svgFractionOrPercentage length] == 0)
    {
        if([svgFractionOrPercentage length] >= 2)
        {
            result = [[svgFractionOrPercentage substringToIndex:[svgFractionOrPercentage length]-1] floatValue]/100.0f;
        }
    }
    else
    {
        result = [svgFractionOrPercentage floatValue];
    }
    return result;
}
@end

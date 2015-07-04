//
//  SVGRenderer+PDF.m
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
//  Created by Glenn Howes on 2/4/14.
//

#import "SVGgh.h"

CGContextRef	CreatePDFContext(const CGRect mediaRect, CFMutableDataRef theData)
{
	CGContextRef result = 0;
	if(theData != 0)
	{
		CGDataConsumerRef theConsumer =CGDataConsumerCreateWithCFData(theData);
		if(theConsumer != 0)
		{
			result = CGPDFContextCreate(theConsumer, &mediaRect, NULL);
			CGDataConsumerRelease(theConsumer);
		}
	}
	return result;
}

@implementation SVGtoPDFConverter
+(void) createPDFFromRenderer:(SVGRenderer*)aRenderer intoCallback:(renderPDFCallback_t)callback
{
    [[SVGRenderer rendererQueue] addOperationWithBlock:^{
        CGRect boundingBox = aRenderer.viewRect;
        NSData* theResult = nil;
        CFMutableDataRef pdfData = CFDataCreateMutable(NULL, 0);
        if(pdfData != 0)
        {
            CGContextRef quartzContext = CreatePDFContext(boundingBox, pdfData);
            CGContextBeginPage(quartzContext, &boundingBox);
            CGContextSaveGState(quartzContext);
            
            CGContextTranslateCTM(quartzContext, 0, boundingBox.size.height);
            CGContextScaleCTM(quartzContext, 1.0, -1.0);
            [aRenderer renderIntoContext:quartzContext];
            
            CGContextEndPage(quartzContext);
            CGContextRestoreGState(quartzContext);
            CGContextFlush(quartzContext);
            
            CGContextRelease(quartzContext);
            theResult = [(__bridge NSMutableData*)pdfData copy];
            CFRelease(pdfData);
        }
        callback(theResult);
    }];
}
@end

//
//  SVGghTests.m
//  SVGghTests
// The MIT License (MIT)

//  Copyright (c) 2011-2016 Glenn R. Howes

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
//

#import <XCTest/XCTest.h>
#import <SVGgh/SVGgh.h>
#import "SVGUtilities.h"


@interface SVGghTests : XCTestCase

@end

@implementation SVGghTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) testTransformParsing
{
    NSArray* testTransforms = @[@"", @"     translate( 3, -1.1)", @"matrix ( 1 0 0 1 -21 21 ) ", @" scale(3), scale(4, 3), skewX(1) skewY(-2)" ];
    
    for(NSString* aTransformString in testTransforms)
    {// I replaced a method to generate an affine transform with something faster and this test is just to see they agree.
        CGAffineTransform canonicalVersion = SVGTransformToCGAffineTransformSlow(aTransformString);
        CGAffineTransform fastVersion =SVGTransformToCGAffineTransform(aTransformString);
        XCTAssertTrue(CGAffineTransformEqualToTransform(canonicalVersion, fastVersion), @"Divergent results with: %@", aTransformString);
    }
}

- (UIColor*)pixelColorInImage:(UIImage*)image atX:(int)x atY:(int)y { // from StackOverflow http://stackoverflow.com/questions/3284185/get-pixel-color-of-uiimage
    
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    int pixelInfo = ((image.size.width  * y) + x ) * 4; // 4 bytes per pixel
    if(pixelInfo >= 0 && pixelInfo < CFDataGetLength(pixelData))
    {
        UInt8 red   = data[pixelInfo + 0];
        UInt8 green = data[pixelInfo + 1];
        UInt8 blue  = data[pixelInfo + 2];
        UInt8 alpha = data[pixelInfo + 3];
        CFRelease(pixelData);
        
        return [UIColor colorWithRed:red/255.0f
                               green:green/255.0f
                                blue:blue/255.0f
                               alpha:alpha/255.0f];
    }
    else
    {
        CFRelease(pixelData);
        return nil;
    }
}

-(NSString*) baseSVGWithFrame:(CGRect)frame
{
    NSString* result = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <svg viewport-fill=\"none\"  x=\"%f\" y=\"%f\" width=\"%f\" height=\"%f\" viewBox=\"%f, %f, %f, %f\" > <g  fill=\"none\" stroke=\"none\">INSERT_CONTENT_HERE</g></svg>",
                        frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
    
    return result;
}



-(void) testImageCreation
{
    [self testImageCreationForFrame:CGRectMake(40, 0, 200, 400)];
    [self testImageCreationForFrame:CGRectMake(0, 40, 200, 400)];
    [self testImageCreationForFrame:CGRectMake(0.0, 0.0, 200, 400)];
    // images should adjust the origin so it isn't cut off
    [self testImageCreationForFrame:CGRectMake(-50, -100, 200, 400)];
    
}

-(void) testImageCreationForFrame:(CGRect)frame
{
    NSString* frameString = NSStringFromCGRect(frame);
    NSString* baseSVG = [self baseSVGWithFrame:frame];
    NSString* greenRectangle = [NSString stringWithFormat:@"<rect x=\"%f\" y=\"%f\" width=\"%f\" height=\"%f\" fill=\"#00FF00\" stroke=\"#00FF00\" />", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
    
    NSString* svgToRender = [baseSVG stringByReplacingOccurrencesOfString:@"INSERT_CONTENT_HERE" withString:greenRectangle];
    SVGRenderer* renderer = [[SVGRenderer alloc] initWithString:svgToRender];
    
    //  XCTAssertNil(renderer.parserError, [NSString stringWithFormat:@"Error making renderer from baseSVG, %@", renderer.parserError]);
    
    CGRect extractedFrame = renderer.viewRect;
    XCTAssert(CGRectEqualToRect(extractedFrame, frame), @"Expected one frame got another for %@", frameString);
    
    CGSize bitmapSize = CGSizeMake(extractedFrame.size.width*2.0, extractedFrame.size.height*2.0); // double size
    UIImage* image = [renderer asImageWithSize:bitmapSize andScale:2.0];
    XCTAssertNotNil(image, @"No image from Renderer for %@", frameString);
    
    UIColor* topLeftColor = [self pixelColorInImage:image atX:0.0 atY:0.0];
    XCTAssertNotNil(topLeftColor, @"No topLeftColor for %@", frameString);
    UIColor*bottomRightColor = [self pixelColorInImage:image atX:bitmapSize.width-1.0 atY:bitmapSize.height-1.0];
    XCTAssertNotNil(bottomRightColor, @"No bottomRightColor for %@", frameString);
    UIColor* greenColor = UIColorFromSVGColorString(@"#00FF00");
    
    XCTAssertEqualObjects(topLeftColor, greenColor, @"Not Green for %@", frameString);
    XCTAssertEqualObjects(bottomRightColor, greenColor, @"Not Green for %@", frameString);
}



-(void) testRectParsing
{// I replaced a method to generate a rect from a string with something faster and this test is just to see they agree
    NSString* rectString = @"-1 -1 2.4 778.8";
    CGRect fastVersion = SVGStringToRect(rectString);
    
    CGRect canonicalVersion = SVGStringToRectSlow(rectString);
    
    XCTAssertTrue(CGRectEqualToRect(canonicalVersion, fastVersion), @"Divergent Rect results with: %@", rectString);
    
    rectString = @"-1 -1 1 1";
    fastVersion = SVGStringToRect(rectString);
    canonicalVersion = SVGStringToRectSlow(rectString);
    
    XCTAssertTrue(CGRectEqualToRect(canonicalVersion, fastVersion), @"Divergent Rect results with: %@", rectString);
}

-(void)testUtilities
{
    NSDictionary* defaults = DefaultSVGDrawingAttributes();
    XCTAssertEqualObjects(defaults[@"stroke-dasharray"], @"none", @"Not setting default stroke-dasharray properly; %@", defaults[@"stroke-dasharray"]);
}

-(void)testArcConversion
{
    NSString* aPath = SVGArcFromSensibleParameters(100, 100, 0,
                                                   0, 180);
    
    XCTAssertEqualObjects(aPath, @"a 100 100 0 0 1 200.00 0.00", @"Unexpected easy String");
    
    aPath = SVGArcFromSensibleParameters(100, 100, 0,
                                         0, 90);
    XCTAssertEqualObjects(aPath, @"a 100 100 0 0 1 100.00 -100.00", @"Unexpected easy String");
    
    
    aPath = SVGArcFromSensibleParameters(100, 100, 0,
                                         0, 270);
    XCTAssertEqualObjects(aPath, @"a 100 100 0 1 1 100.00 100.00", @"Unexpected String");
}

-(void) testMorphing
{
    NSString* greyColor =  MorphColorString(@"white", @"black", 0.5);
    XCTAssertEqualObjects(greyColor, @"rgb(127,127,127)", @"Unexpected grey: %@", greyColor);
    NSString* aColor =  MorphColorString(@"#AAA", @"#DDD", 1.0);
    XCTAssertEqualObjects(aColor,  @"#DDD", @"Unexpected color: %@", aColor);
    aColor =  MorphColorString(@"#AAA", @"#DDD", 0.0);
    XCTAssertEqualObjects(aColor,  @"#AAA", @"Unexpected color: %@", aColor);
    
    
    aColor =  MorphColorString(@"#606060", @"#808080", 0.5);
    XCTAssertEqualObjects(aColor,  @"rgb(112,112,112)", @"Unexpected fractional Color: %@", aColor);
    aColor =  MorphColorString(@"#808080", @"#808080", 0.5);
    XCTAssertEqualObjects(aColor,  @"rgb(128,128,128)", @"Unexpected fractional Color: %@", aColor);
}

-(void) testStyleMorphing
{
    NSDictionary* oldAttributes  = @{@"style":@"stroke-width:8;fill:black;stroke-linecap:round;stroke:purple"};
    NSDictionary* newAttributes  = @{@"style":@"stroke-width:6;fill:blue", @"stroke":@"red"};
    
    NSDictionary* morphedAttributes =  SVGMorphStyleAttributes(oldAttributes, newAttributes, 0.5);
    NSString* morphedStyle = [morphedAttributes objectForKey:@"style"];
    XCTAssertNotNil(morphedStyle, @"Expected a Morphed Style");
    NSString* lineWidth = [SVGToQuartz valueForStyleAttribute:@"stroke-width" fromDefinition:morphedAttributes];
    XCTAssertEqualObjects(lineWidth,  @"7", @"Unexpected Linewidth of 7 got:%@", lineWidth);
    
}

-(void) testHTMLColors
{
    XCTAssertNotNil(UIColorFromSVGColorString(@"BURLYWOOD"));
    XCTAssertNotNil(UIColorFromSVGColorString(@"coral"));
    XCTAssertNotNil(UIColorFromSVGColorString(@"lemonCHIFFON"));
    XCTAssertNil(UIColorFromSVGColorString(@"cherry"));
}

-(void) testStyleMerge
{
    NSDictionary* parentDictionary = @{@"id":@"TEST", @"style":@"fill:yellow;stroke:#CCC;stroke-width:8", @"opacity":@"1.0"};
    NSDictionary* deltaDictionary = @{@"id":@"BLAW", @"style":@"fill:green;opacity:0.5", @"stroke-width":@"4"};
    NSDictionary* mergedDictionary = SVGMergeStyleAttributes(parentDictionary, deltaDictionary, nil);
    NSDictionary* wantedDictionary = @{@"id":@"TEST", @"stroke-width":@"4", @"stroke":@"#CCC", @"fill":@"green", @"opacity":@"0.5"};
    XCTAssertEqualObjects(mergedDictionary, wantedDictionary, @"Expected a different style attribute merge");
    
    parentDictionary = @{@"id":@"TEST", @"style":@"fill:url(#testGradient);stroke:#CCC;stroke-width:8", @"color":@"blue",@"opacity":@"1.0"};
    deltaDictionary = @{@"id":@"HAW", @"style":@"fill:#deb887;color:#deb887", @"stroke-width":@"4"};
    mergedDictionary = SVGMergeStyleAttributes(parentDictionary, deltaDictionary, ^BOOL(NSString *key, id sourceAttribute, id destAttribute) {
        BOOL result = YES;
        if([key isEqualToString:@"fill"] && [sourceAttribute hasPrefix:@"url("] && ![destAttribute isEqualToString:@"currentColor"])
        {
            result = NO;
        }
        return result;
    });
    wantedDictionary = @{@"id":@"TEST", @"stroke-width":@"4", @"stroke":@"#CCC", @"fill":@"url(#testGradient)", @"opacity":@"1.0",@"color":@"#deb887"};
    
    XCTAssertEqualObjects(mergedDictionary, wantedDictionary, @"Expected a url to be honored");
    
    
    deltaDictionary = @{@"id":@"HAW", @"style":@"fill:currentColor;opacity:0.5", @"color":@"orange", @"stroke-width":@"4"};
    mergedDictionary = SVGMergeStyleAttributes(parentDictionary, deltaDictionary, ^BOOL(NSString *key, id sourceAttribute, id destAttribute) {
        BOOL result = YES;
        if([key isEqualToString:@"fill"] && [sourceAttribute hasPrefix:@"url("] && ![destAttribute isEqualToString:@"currentColor"])
        {
            result = NO;
        }
        return result;
    });
    wantedDictionary = @{@"id":@"TEST", @"stroke-width":@"4", @"stroke":@"#CCC", @"fill":@"currentColor", @"opacity":@"0.5",@"color":@"orange"};
    XCTAssertEqualObjects(mergedDictionary, wantedDictionary, @"Expected fill to be changed");
}


@end

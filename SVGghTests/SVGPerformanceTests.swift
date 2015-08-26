//
//  SVGPerformanceTests.swift
//  SVGgh
//
//  Created by Glenn Howes on 7/24/15.
//  Copyright © 2015 Generally Helpful. All rights reserved.
//

import XCTest

class SVGPerformanceTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func newURLAtSubpath(subpath:String)->NSURL
    {
        let myBundle = NSBundle(forClass: self.dynamicType)
        return myBundle.URLForResource(subpath, withExtension:"svg")!
    }
    
    func testLoadPerformance() {
        // This is an example of a performance test case.
        let myArtwork = newURLAtSubpath("Artwork/Eyes")
        self.measureBlock {
            // Put the code you want to measure the time of here.
            let renderer = SVGRenderer(contentsOfURL:myArtwork)
            XCTAssertNotNil(renderer, "Render was nil")
        }
    }
    
    func fileTest(fileAtPath:String)
    {
        let maximumSize = CGSizeMake(1024, 1024)
        let myArtwork = newURLAtSubpath(fileAtPath)
        let renderer = SVGRenderer(contentsOfURL:myArtwork)
        let documentSize = renderer.viewRect.size
        let interiorAspectRatio = maximumSize.width/maximumSize.height
        let rendererAspectRatio = documentSize.width/documentSize.height
        var fittedScaling = 1.0 as CGFloat
        if(interiorAspectRatio >= rendererAspectRatio)
        {
            fittedScaling = maximumSize.height/documentSize.height
        }
        else
        {
            fittedScaling = maximumSize.width/documentSize.width
        }

        
        let scaledWidth = floor(documentSize.width*fittedScaling) as CGFloat
        let scaleHeight = floor(documentSize.height*fittedScaling) as CGFloat
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaledWidth, scaleHeight), false, 1.0);
        let quartzContext = UIGraphicsGetCurrentContext();
        CGContextClearRect(quartzContext, CGRectMake(0, 0, scaledWidth, scaleHeight));
        CGContextSaveGState(quartzContext);
        CGContextTranslateCTM(quartzContext, (maximumSize.width-scaledWidth)/2.0, (maximumSize.height-scaleHeight)/2.0);
        CGContextScaleCTM(quartzContext, fittedScaling, fittedScaling);

        self.measureBlock
        {
            renderer.renderIntoContext(quartzContext!)
            UIGraphicsEndImageContext();
        }
    }
    
    func testRenderPerformanceGradients()
    {
        fileTest("Artwork/Eyes")
    }
    
    func testRenderPerformanceMixedMedia()
    {
        fileTest("Artwork/Superstar")
    }
    
    
    func testRenderPerformanceCurvedText()
    {
        fileTest("Artwork/TextOnCurve")
    }
    
    
    func testRenderPaths()
    {
        fileTest("Artwork/Creatures")
    }
}

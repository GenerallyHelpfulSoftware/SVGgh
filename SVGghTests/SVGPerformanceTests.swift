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
    
    func newURLAtSubpath(_ subpath:String)->NSURL
    {
        let myBundle = Bundle(for: type(of: self))
        return myBundle.url(forResource: subpath, withExtension: "svg")! as NSURL
    }
    
    func testLoadPerformance() {
        // This is an example of a performance test case.
        let myArtwork = newURLAtSubpath("Artwork/Eyes")
        
        self.measure {
            // Put the code you want to measure the time of here.
            let renderer = SVGRenderer(contentsOf:myArtwork as URL)
            XCTAssertNotNil(renderer, "Render was nil")
        }
    }
    
    func fileTest(_ fileAtPath:String)
    {
        let maximumSize = CGSize(width: 1024, height: 1024)
        let myArtwork = newURLAtSubpath(fileAtPath)
        let renderer = SVGRenderer(contentsOf:myArtwork as URL)
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
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scaledWidth, height: scaleHeight), false, 1.0)
        if let quartzContext = UIGraphicsGetCurrentContext()
        {
            quartzContext.clear(CGRect(x: 0, y: 0, width: scaledWidth, height: scaleHeight))
            quartzContext.saveGState()
            
            quartzContext.translateBy(x: (maximumSize.width-scaledWidth)/2.0, y: (maximumSize.height-scaleHeight)/2.0)
            
            quartzContext.scaleBy(x: fittedScaling, y: fittedScaling)

            self.measure
            {
                renderer.render(into: quartzContext)
                UIGraphicsEndImageContext()
            }
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

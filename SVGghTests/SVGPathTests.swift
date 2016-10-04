//
//  SVGPathTests.swift
//  SVGgh
//
//  Created by Glenn Howes on 8/14/16.
//  Copyright © 2016 Generally Helpful. All rights reserved.
//

import XCTest


class SVGPathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testArcs() {
        
        guard let cgPath = SVGPathGenerator.newCGPath(fromSVGPath: "M0 0 a 10 20 30 0 0 10 10 a 20 20 0 0 1 10 10 a 30 30 0 1 1 25 25 a 40 40 0 1 0 20 20", whileApplying:  CGAffineTransform.identity) else
        {
            XCTFail("Arc not created")
            return
        }
        
        let asString = cgPath.asString()
        XCTAssert(!asString.isEmpty)
        XCTAssertEqual(asString, "M (0.0, 0.0)\nL (10.0, 10.0)\nL (20.0, 10.0)\nL (20.0, 20.0)\nQ (30.0, 30.0, 40.0, 40.0)\nC (50.0, 50.0, 60.0, 60.0, 70.0, 70.0)\nZ\n")
        
    }
    
    func testFrog() {
        
        guard let cgPath = SVGPathGenerator.newCGPath(fromSVGPath: "M 170 207C139 183 40 199 41 109 A18 18 0 1 1 56 75", whileApplying:  CGAffineTransform.identity) else
        {
            XCTFail("Arc not created")
            return
        }
        
        let asString = cgPath.asString()
        XCTAssert(!asString.isEmpty)
        XCTAssertEqual(asString, "M (170.0, 207.0)\nC (139.0, 183.0, 40.0, 199.0, 41.0, 109.0)\nL (41.0000007655841, 109.000000337679)\nC (31.6108020503137, 104.858676108513, 27.356559217929, 93.8900200541057, 31.4978834470946, 84.5008213388353)\nC (35.6392076762602, 75.1116226235649, 46.6078637306675, 70.8573797911802, 55.997062445938, 74.9987040203458)\nC (55.9970633126063, 74.99870440261, 55.9970641462961, 74.9987047703283, 55.9970650129644, 74.9987051525926)\n")
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

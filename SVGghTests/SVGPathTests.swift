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
        XCTAssertEqual(asString, "M (0.00, 0.00)\nL (-0.00, 0.00)\nC (-1.26, 8.86, 3.14, 13.26, 10.00, 10.00)\nL (10.00, 10.00)\nC (14.44, 12.00, 18.00, 15.56, 20.00, 20.00)\nL (20.00, 20.00)\nC (17.44, 3.63, 28.63, -11.72, 45.00, -14.28)\nC (61.37, -16.84, 76.72, -5.65, 79.28, 10.72)\nC (81.84, 27.09, 70.65, 42.44, 54.28, 45.00)\nC (51.20, 45.48, 48.07, 45.48, 45.00, 45.00)\nL (45.00, 45.00)\nC (24.87, 35.91, 1.17, 44.87, -7.92, 65.00)\nC (-17.00, 85.13, -8.05, 108.83, 12.08, 117.92)\nC (32.22, 127.00, 55.91, 118.05, 65.00, 97.92)\nC (69.72, 87.45, 69.72, 75.46, 65.00, 65.00)\n")
        
    }
    
    func testFrog() {
        
        guard let cgPath = SVGPathGenerator.newCGPath(fromSVGPath: "M 170 207C139 183 40 199 41 109 A18 18 0 1 1 56 75", whileApplying:  CGAffineTransform.identity) else
        {
            XCTFail("Arc not created")
            return
        }
        
        let asString = cgPath.asString()
        XCTAssert(!asString.isEmpty)
        XCTAssertEqual(asString, "M (170.00, 207.00)\nC (139.00, 183.00, 40.00, 199.00, 41.00, 109.00)\nL (41.00, 109.00)\nC (31.61, 104.86, 27.36, 93.89, 31.50, 84.50)\nC (35.64, 75.11, 46.61, 70.86, 56.00, 75.00)\nC (56.00, 75.00, 56.00, 75.00, 56.00, 75.00)\n")
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}

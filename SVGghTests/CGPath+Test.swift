//
//  CGPath+Test.swift
//  Scalar2D
//
//  Created by Glenn Howes on 8/13/16.
//  Copyright © 2016 Generally Helpful Software. All rights reserved.
//
// The MIT License (MIT)

//  Copyright (c) 2016 Glenn R. Howes

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
//

import Foundation
import CoreGraphics

public extension CGPath
{
    public func asString() -> String
    {
        let result = NSMutableString()
        
        self.iterate { (element) in
            let points = element.points
            
            switch element.type
            {
                case .moveToPoint:
                    let newPoint = points.pointee
                    let xString = String(format: "%.02f", newPoint.x)
                    let yString = String(format: "%.02f", newPoint.y)
                    result.append("M (\(xString), \(yString))\n")
                case .addLineToPoint:
                    let newPoint = points.pointee
                    let xString = String(format: "%.02f", newPoint.x)
                    let yString = String(format: "%.02f", newPoint.y)
                    result.append("L (\(xString), \(yString))\n")
                case .closeSubpath:
                    result.append("Z\n")
                case .addCurveToPoint:
                    let controlPoint1 = points.pointee
                    let controlPoint2 = points.advanced(by: 1).pointee
                    let nextPoint = points.advanced(by: 2).pointee
                    
                    let controlPoint1XString = String(format: "%.02f", controlPoint1.x)
                    let controlPoint1YString = String(format: "%.02f", controlPoint1.y)
                    let controlPoint2XString = String(format: "%.02f", controlPoint2.x)
                    let controlPoint2YString = String(format: "%.02f", controlPoint2.y)
                    
                    let xString = String(format: "%.02f", nextPoint.x)
                    let yString = String(format: "%.02f", nextPoint.y)
                    
                    result.append("C (\(controlPoint1XString), \(controlPoint1YString), \(controlPoint2XString), \(controlPoint2YString), \(xString), \(yString))\n")
                    
                case .addQuadCurveToPoint:
                    
                    let quadControlPoint = points.pointee
                    let nextPoint = points.advanced(by: 1).pointee
                    let quadControlPointXString = String(format: "%.02f", quadControlPoint.x)
                    let quadControlPointYString = String(format: "%.02f", quadControlPoint.y)
                    let xString = String(format: "%.02f", nextPoint.x)
                    let yString = String(format: "%.02f", nextPoint.y)
                    result.append("Q (\(quadControlPointXString), \(quadControlPointYString), \(xString), \(yString))\n")
            }

        }
        return result as String
    }
}

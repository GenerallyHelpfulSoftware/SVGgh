//
//  SVGghDebuggingViewController.swift
//  SVGgh Debugging App
//
//  Created by Glenn Howes on 9/20/21.
//  Copyright © 2021 Generally Helpful. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SVGgh

@available(iOS 14.0, *)
struct SVGCardView : View, Animatable
{
    var animatableData : Double
    {
        set
        {
            self.rotation = newValue
        }
        
        get
        {
            return self.rotation
        }
    }
    @State var rotation : Double = 0.0
    @State var cardName : String = "Jack_Hearts"
    
    private func pickRandomCard()
    {
        cardName = ["Queen_Hearts", "King_Hearts", "Jack_Hearts", "Queen_Spades", "King_Spades", "Jack_Spades", "Queen_Diamonds", "King_Diamonds", "Jack_Diamonds", "Queen_Clubs", "King_Clubs", "Jack_Clubs"].randomElement()!
    }
    
    var body : some View
    {
        VStack(alignment: .center, spacing: 8.0)
        {
            Spacer()
            Text("Tap to Flip").font(.headline)
            ZStack
            {
                if animatableData <= 90.0
                {
                    SVGView(resourceName: cardName)
                    .aspectRatio(contentMode: .fit)
                }
                if animatableData >= 90.0
                {
                    SVGView(resourceName: "Card_Back").currentColor(Color.blue)
                            .aspectRatio(contentMode: .fit)
                }
            }.rotation3DEffect(Angle(degrees: rotation), axis: (x: 0.0, y: 1.0, z: 0.0)).onTapGesture {
                withAnimation
                {
                    let newRotation = (rotation == 0.0) ? 180.0 : 0.0
                    if newRotation == 0.0
                    {
                        pickRandomCard()
                    }
                    rotation = newRotation
                    
                }
            }.onAppear
            {
                withAnimation
                {
                    pickRandomCard()
                    rotation = 180.0
                }
            }
            Spacer()
        }
    }
}

@available(iOS 14.0, *)
struct SVGTestView : View
{
    var body : some View
    {
        VStack
        {
            SVGCardView()
        }.background(Color.white)
    }
    
    
}

extension SVGghDebuggingViewController
{
    @available(iOS 14.0, *)
    @objc func createSwiftUIExample() -> UIViewController
    {
        let result = UIHostingController(rootView: SVGTestView())
        result.view.translatesAutoresizingMaskIntoConstraints = true
        return result
    }
}

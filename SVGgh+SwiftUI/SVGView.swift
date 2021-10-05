//
//  SVGView.swift
//  SVGgh Debugging App
//
//  Created by Glenn Howes on 9/20/21.
//  Copyright © 2021 Generally Helpful. All rights reserved.
//

import SwiftUI
import SVGgh
import os.log

@available(iOS 14.0.0, *)
struct SVGView: UIViewRepresentable, Identifiable {
    var id: String
    
    private var svgView : SVGDocumentView
    @State var currentColor : Color?
    
    init(resourceName : String, bundle : Bundle? = nil)
    {
        self.id = resourceName
        self.svgView = SVGDocumentView()
        let renderer = SVGRenderer(dataAssetNamed: resourceName, with: bundle)
        if(renderer == nil)
        {
            os_log("No SVG resource named %@", type: .debug, resourceName)
        }
        self.svgView.renderer = renderer
        self.svgView.backgroundColor = UIColor.clear
        self.svgView.contentMode = .scaleAspectFit
    }
    
    func makeUIView(context: Context) -> SVGDocumentView {
        let result = self.svgView
        
        return result
    }
    
    func updateUIView(_ uiView: SVGDocumentView, context: Context) {
        
    }
    
    typealias UIViewType = SVGDocumentView
    
    public func currentColor(_ currentColor : Color) -> SVGView
    {
        self.svgView.defaultColor = UIColor(currentColor)
        return self
    }
    
}

@available(iOS 14.0.0, *)
struct SVGView_Previews: PreviewProvider {
    static var previews: some View {
        SVGView(resourceName: "Eyes", bundle: nil)
    }
}

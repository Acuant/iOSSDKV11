//
//  CameraDocumentOverlay.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/5/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

public class CameraDocumentOverlayView : CAShapeLayer{
    
    public var alwaysHideBox: Bool = false
    
    private var isAnimating = false
    private var isShown = false
    
    init(options: CameraOptions){
        self.alwaysHideBox = !(options.allowBox)
        super.init()
        self.fillColor = nil
        self.path = UIBezierPath(rect: self.bounds).cgPath
        self.strokeColor = UIColor.red.cgColor
        self.fillColor = UIColor.red.cgColor
        self.opacity = 0
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func showBorder(color: CGColor?){
        if(!self.alwaysHideBox){
            self.strokeColor = color
            self.fillColor = color
            self.opacity = 0.45
        }
    }
    
    public func hideBorder(){
        self.opacity = 0
        self.isShown = false
        self.path = nil
    }
}

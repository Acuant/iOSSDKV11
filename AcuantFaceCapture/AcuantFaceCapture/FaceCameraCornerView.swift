//
//  CameraCornerOverlay.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/27/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
//
//  CameraDocumentOverlay.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/5/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

class FaceCameraCornerView : CAShapeLayer, CAAnimationDelegate{
    private var isAnimating = false
    private var isShown = false
    private var currentColor = UIColor.red.cgColor
    
    enum CornerSide: Int{
        case TopLeft
        case TopRight
        case BottomRight
        case BottomLeft
    }
    
    override init(){
        super.init()
        self.fillColor = nil
        self.path = UIBezierPath(rect: self.bounds).cgPath
        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 2
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool){
        isAnimating = false
    }
    
    func showColor(color: CGColor){
        self.fillColor = color
    }
    
    func showBorder(color: CGColor? = UIColor.red.cgColor){
        self.strokeColor = color
        self.fillColor = color
        if(!isAnimating && !isShown){
            isShown = true
            isAnimating = true
            
            let animShape :CABasicAnimation = CABasicAnimation(keyPath: "opacity")
            animShape.delegate = self
            animShape.duration = 1;
            animShape.fromValue = 0;
            animShape.toValue = 0.45;
            animShape.fillMode = CAMediaTimingFillMode.forwards;
            animShape.isRemovedOnCompletion = false
            
            self.add(animShape, forKey: "opacity")
        }
    }
    
    func hideBorder(){
        self.opacity = 0
        self.strokeColor = UIColor.red.cgColor
    }
}

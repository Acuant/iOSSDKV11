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
    
    public var colorHold: CGColor? = nil
    public var colorCapture: CGColor? = nil
    public var alwaysHideBox: Bool = false
    
    private var isAnimating = false
    private var isShown = false
    private var currentColor = UIColor.red.cgColor
    
    init(options: AcuantCameraOptions){
        self.alwaysHideBox = !(options.allowBox)
        self.colorCapture = options.colorCapturing
        self.colorHold = options.colorHold
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
    
    public func showBorderFromState(state: DocumentCameraController.CameraState = DocumentCameraController.CameraState.Hold) {
        if(!alwaysHideBox) {
            switch state {
            case DocumentCameraController.CameraState.MoveCloser:
                hideBorder()
                break;
            case DocumentCameraController.CameraState.Hold:
                showBorder(color: colorHold!)
                break;
            case DocumentCameraController.CameraState.Steady:
                showBorder(color: colorHold!)
                break;
            case DocumentCameraController.CameraState.Capture:
                showBorder(color: colorCapture!)
                break;
            default://align
                hideBorder()
                break;
            }
        } else {
            hideBorder()
        }
    }
    
    private func showBorder(color: CGColor){
        self.strokeColor = color
        self.fillColor = color
        self.opacity = 0.45
    }
    
    private func hideBorder(){
        self.opacity = 0
        self.isShown = false
        self.path = nil
    }
}

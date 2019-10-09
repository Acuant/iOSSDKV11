//
//  CameraTextView.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/5/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

public class AcuantCameraTextView: CATextLayer{
    public var textSizeDefault : CGFloat = 30
    public var textSizeCapture : CGFloat = 70
    public var backgroundColorDefault : CGColor? = UIColor.black.cgColor
    public var backgroundColorCapture : CGColor? = nil
    public var foregroundColorDefault : CGColor? = UIColor.white.cgColor
    public var foregroundColorCapture : CGColor? = UIColor.red.cgColor
    
    private var isAnimating = false
    private var isShown = false
    private var currentColor = UIColor.red.cgColor
    
    init(autoCapture: Bool = true){
        super.init()
        self.opacity = 0.7
        if(autoCapture){
            self.string = NSLocalizedString("acuant_camera_align", comment: "")
        }else{
            self.string = NSLocalizedString("acuant_camera_manual_capture", comment: "")
        }
        self.alignmentMode = CATextLayerAlignmentMode.center
        self.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)));
        self.cornerRadius = 10;
    }
    
    internal func setFrame(frame: CGRect) {
        self.setDefaultSettings(frame: frame)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func setLookFromState(state: DocumentCameraController.CameraState, frame: CGRect) {
        switch state {
        case DocumentCameraController.CameraState.MoveCloser:
            setDefaultSettings(frame: frame)
            break;
        case DocumentCameraController.CameraState.Hold:
            setCaptureSettings(frame: frame)
            break;
        case DocumentCameraController.CameraState.Steady:
            setDefaultSettings(frame: frame)
            break;
        case DocumentCameraController.CameraState.Capture:
            setCaptureSettings(frame: frame)
            break;
        default://align
            setDefaultSettings(frame: frame)
            break;
        }
    }
    
    private func setDefaultSettings(frame: CGRect){
        self.fontSize = textSizeDefault
        self.backgroundColor = backgroundColorDefault
        self.foregroundColor = foregroundColorDefault
        self.frame = CGRect(x: (frame.width/2)-20, y: (frame.height/2)-150, width: 40, height: 300)
    }
    
    private func setCaptureSettings(frame: CGRect){
        self.fontSize = textSizeCapture
        self.backgroundColor = backgroundColorCapture
        self.foregroundColor = foregroundColorCapture
        self.frame = CGRect(x: (frame.width/2)-50, y: (frame.height/2)-150, width: 100, height: 300)
    }
}

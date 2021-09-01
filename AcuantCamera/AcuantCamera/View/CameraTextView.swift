//
//  CameraTextView.swift
//  AcuantCamera
//
//  Created by John Moon local on 8/5/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

public class CameraTextView: CATextLayer {
    public var textSizeDefault: CGFloat = 30
    public var textSizeCapture: CGFloat = 70
    public var backgroundColorDefault: CGColor? = UIColor.black.cgColor
    public var backgroundColorCapture: CGColor?
    public var foregroundColorDefault: CGColor? = UIColor.white.cgColor
    public var foregroundColorCapture: CGColor? = UIColor.red.cgColor

    var defaultWidth: CGFloat = 300
    var defaultHeight: CGFloat = 40
    var captureWidth: CGFloat = 100
    var captureHeight: CGFloat = 300
    
    public override var string: Any? {
        didSet {
            accessibilityElement?.accessibilityValue = string as? String
        }
    }
    var accessibilityElement: UIAccessibilityElement?

    init(autoCapture: Bool = true) {
        super.init()
        self.opacity = 0.7
        if autoCapture {
            self.string = NSLocalizedString("acuant_camera_align", comment: "")
        } else {
            self.string = NSLocalizedString("acuant_camera_manual_capture", comment: "")
        }
        self.alignmentMode = CATextLayerAlignmentMode.center
        self.cornerRadius = 10
    }
    
    func setFrame(frame: CGRect) {
        self.setDefaultSettings(frame: frame)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    ///Aligns text vertically
    public override func draw(in context: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height-fontSize)/2 - fontSize/10

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)
        super.draw(in: context)
        context.restoreGState()
    }

    public func setDefaultSettings(frame: CGRect) {
        self.fontSize = textSizeDefault
        self.backgroundColor = backgroundColorDefault
        self.foregroundColor = foregroundColorDefault
        self.frame = CGRect(x: frame.width / 2 - defaultWidth / 2,
                            y: frame.height / 2 - defaultHeight / 2,
                            width: defaultWidth,
                            height: defaultHeight)
    }

    public func setCaptureSettings(frame: CGRect) {
        self.fontSize = textSizeCapture
        self.backgroundColor = backgroundColorCapture
        self.foregroundColor = foregroundColorCapture
        self.frame = CGRect(x: frame.width / 2 - captureWidth / 2,
                            y: frame.height / 2 - captureHeight / 2,
                            width: captureWidth,
                            height: captureHeight)
    }

    func setVerticalDefaultSettings(frame: CGRect) {
        self.fontSize = textSizeDefault
        self.backgroundColor = backgroundColorDefault
        self.foregroundColor = foregroundColorDefault
        self.frame = CGRect(x: frame.width / 2 - defaultHeight / 2,
                            y: frame.height / 2 - defaultWidth / 2,
                            width: defaultHeight,
                            height: defaultWidth)
    }

    func setVerticalCaptureSettings(frame: CGRect) {
        self.fontSize = textSizeCapture
        self.backgroundColor = backgroundColorCapture
        self.foregroundColor = foregroundColorCapture
        self.frame = CGRect(x: frame.width / 2 - captureHeight / 2,
                            y: frame.height / 2 - captureWidth / 2,
                            width: captureHeight,
                            height: captureWidth)
    }

}

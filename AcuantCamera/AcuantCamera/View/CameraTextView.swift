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
    public var textSizeCapture: CGFloat = 50
    public var backgroundColorDefault: CGColor? = UIColor.black.cgColor
    public var backgroundColorCapture: CGColor?
    public var foregroundColorDefault: CGColor? = UIColor.white.cgColor
    public var foregroundColorCapture: CGColor? = UIColor.red.cgColor

    private let frameLargeSideScreenProportion = 0.35
    private let frameSmallSideScreenProportion = UIDevice.current.userInterfaceIdiom == .pad ? 0.05 : 0.1

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
            self.string = "acuant_camera_align".localizedDocString
        } else {
            self.string = "acuant_camera_manual_capture".localizedDocString
        }
        self.alignmentMode = CATextLayerAlignmentMode.center
        self.cornerRadius = 10
        self.fontSize = textSizeDefault
        self.contentsScale = UIScreen.main.scale
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
    
    override public func layoutSublayers() {
        super.layoutSublayers()
        fitTextToFrame()
    }

    private func fitTextToFrame() {
        var stringSize: CGSize  {
            get { return (string as? String)!.size(ofFont: UIFont(name: (font as! UIFont).fontName, size: fontSize)!) }
        }
        let margin: CGFloat = 2
        while max(frame.width, frame.height) <= max(stringSize.width, stringSize.height) + margin {
            fontSize -= 1
        }
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
        let width = max(frame.width, frame.height) * frameLargeSideScreenProportion
        let height = min(frame.width, frame.height) * frameSmallSideScreenProportion
        self.frame = CGRect(x: frame.width / 2 - width / 2,
                            y: frame.height / 2 - height / 2,
                            width: width,
                            height: height)
        fitTextToFrame()
    }

    public func setCaptureSettings(frame: CGRect) {
        self.fontSize = textSizeCapture
        self.backgroundColor = backgroundColorCapture
        self.foregroundColor = foregroundColorCapture
        let width = max(frame.width, frame.height) * frameLargeSideScreenProportion
        let height = min(frame.width, frame.height) * frameSmallSideScreenProportion
        self.frame = CGRect(x: frame.width / 2 - width / 2,
                            y: frame.height / 2 - height / 2,
                            width: width,
                            height: height)
        fitTextToFrame()
    }

    func setVerticalDefaultSettings(frame: CGRect) {
        self.fontSize = textSizeDefault
        self.backgroundColor = backgroundColorDefault
        self.foregroundColor = foregroundColorDefault
        let height = max(frame.width, frame.height) * frameLargeSideScreenProportion
        let width = min(frame.height, frame.width) * frameSmallSideScreenProportion
        self.frame = CGRect(x: frame.width / 2 - width / 2,
                            y: frame.height / 2 - height / 2,
                            width: width,
                            height: height)
        fitTextToFrame()
    }

    func setVerticalCaptureSettings(frame: CGRect) {
        self.fontSize = textSizeCapture
        self.backgroundColor = backgroundColorCapture
        self.foregroundColor = foregroundColorCapture
        let height = max(frame.width, frame.height) * frameLargeSideScreenProportion
        let width = min(frame.height, frame.width) * frameSmallSideScreenProportion
        self.frame = CGRect(x: frame.width / 2 - width / 2,
                            y: frame.height / 2 - height / 2,
                            width: width,
                            height: height)
        fitTextToFrame()
    }

}

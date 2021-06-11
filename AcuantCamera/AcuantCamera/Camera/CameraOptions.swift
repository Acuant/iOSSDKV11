//
//  AccuantCameraSettings.swift
//  AcuantCamera
//
//  Created by Sergey Matsev on 9/27/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public class CameraOptions : NSObject{
    
    public let timeInMsPerDigit: Int
    public let digitsToShow: Int
    public let allowBox: Bool
    public let autoCapture: Bool
    public let hideNavigationBar : Bool
    public let bracketLengthInHorizontal : Int
    public let bracketLengthInVertical: Int
    public let defaultBracketMarginWidth : CGFloat
    public let defaultBracketMarginHeight : CGFloat
    public let colorHold: CGColor
    public let colorCapturing: CGColor
    public let colorBracketAlign: CGColor
    public let colorBracketCloser: CGColor
    public let colorBracketHold: CGColor
    public let colorBracketCapture: CGColor
    public let defaultImageUrl: String
    public let showBackButton: Bool
    
    public init(timeInMsPerDigit: Int = 900,
                digitsToShow: Int = 2,
                allowBox : Bool = true,
                autoCapture : Bool = true,
                hideNavigationBar : Bool = true,
                bracketLengthInHorizontal : Int = 80,
                bracketLengthInVertical : Int = 50,
                defaultBracketMarginWidth : CGFloat = 0.5,
                defaultBracketMarginHeight : CGFloat = 0.6,
                colorHold: CGColor = UIColor.yellow.cgColor,
                colorCapturing: CGColor = UIColor.green.cgColor,
                colorBracketAlign: CGColor = UIColor.black.cgColor,
                colorBracketCloser: CGColor = UIColor.red.cgColor,
                colorBracketHold: CGColor = UIColor.yellow.cgColor,
                colorBracketCapture: CGColor = UIColor.green.cgColor,
                defaultImageUrl: String = "",
                showBackButton: Bool = true) {
        
        self.timeInMsPerDigit = timeInMsPerDigit
        self.digitsToShow = digitsToShow
        self.allowBox = allowBox
        self.autoCapture = autoCapture
        self.hideNavigationBar = hideNavigationBar
        self.bracketLengthInHorizontal = bracketLengthInHorizontal
        self.bracketLengthInVertical = bracketLengthInVertical
        self.defaultBracketMarginWidth = defaultBracketMarginWidth
        self.defaultBracketMarginHeight = defaultBracketMarginHeight
        self.colorHold = colorHold
        self.colorCapturing = colorCapturing
        self.colorBracketAlign = colorBracketAlign
        self.colorBracketCloser = colorBracketCloser
        self.colorBracketHold = colorBracketHold
        self.colorBracketCapture = colorBracketCapture
        self.defaultImageUrl = defaultImageUrl
        self.showBackButton = showBackButton
    }
}

//
//  AccuantCameraSettings.swift
//  AcuantCamera
//
//  Created by Sergey Matsev on 9/27/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public class FaceCameraOptions : NSObject{
    
    public let totalCaptureTime: Int
    public let bracketColorDefault: CGColor
    public let bracketColorError: CGColor
    public let bracketColorGood: CGColor
    public let fontColorDefault: CGColor
    public let fontColorError: CGColor
    public let fontColorGood: CGColor
    public let defaultImageUrl: String
    public let showOval: Bool
    
    public init(totalCaptureTime: Int = 2,
                bracketColorDefault: CGColor = UIColor.black.cgColor,
                bracketColorError: CGColor = UIColor.red.cgColor,
                bracketColorGood: CGColor = UIColor.green.cgColor,
                fontColorDefault: CGColor = UIColor.white.cgColor,
                fontColorError: CGColor = UIColor.red.cgColor,
                fontColorGood: CGColor = UIColor.green.cgColor,
                defaultImageUrl: String = "acuant_default_face_image.png",
                showOval: Bool = false) {

        self.totalCaptureTime = totalCaptureTime
        self.bracketColorDefault = bracketColorDefault
        self.bracketColorError = bracketColorError
        self.bracketColorGood = bracketColorGood
        self.fontColorDefault = fontColorDefault
        self.fontColorError = fontColorError
        self.fontColorGood = fontColorGood
        self.defaultImageUrl = defaultImageUrl
        self.showOval = showOval
    }
}

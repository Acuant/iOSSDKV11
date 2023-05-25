//
//  AccuantCameraSettings.swift
//  AcuantCamera
//
//  Created by Sergey Matsev on 9/27/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public class CameraOptions: NSObject {
    public let hideNavigationBar: Bool
    public let showBackButton: Bool
    public let placeholderImageName: String?
    public let autoCapture: Bool
    public let showDetectionBox: Bool
    public let bracketLengthInHorizontal: Int
    public let bracketLengthInVertical: Int
    public let defaultBracketMarginWidth: CGFloat
    public let defaultBracketMarginHeight: CGFloat
    public let textForCameraPaused: String
    public let backButtonText: String
    
    init(hideNavigationBar: Bool = true,
         showBackButton: Bool = true,
         placeholderImageName: String? = nil,
         autoCapture: Bool = true,
         showDetectionBox: Bool = true,
         bracketLengthInHorizontal: Int = 80,
         bracketLengthInVertical: Int = 50,
         defaultBracketMarginWidth: CGFloat = 0.5,
         defaultBracketMarginHeight: CGFloat = 0.6,
         textForCameraPaused: String = "CAMERA PAUSED",
         backButtonText: String = "BACK") {
        self.hideNavigationBar = hideNavigationBar
        self.showBackButton = showBackButton
        self.placeholderImageName = placeholderImageName
        self.autoCapture = autoCapture
        self.showDetectionBox = showDetectionBox
        self.bracketLengthInVertical = bracketLengthInVertical
        self.bracketLengthInHorizontal = bracketLengthInHorizontal
        self.defaultBracketMarginWidth = defaultBracketMarginWidth
        self.defaultBracketMarginHeight = defaultBracketMarginHeight
        self.textForCameraPaused = textForCameraPaused
        self.backButtonText = backButtonText
    }
}

//
//  DocumentCameraOptions.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 13/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import Foundation
import UIKit

@objc public enum DocumentCameraState: Int {
    case align, moveCloser, tooClose, steady, hold, capture
}

@objcMembers public class DocumentCameraOptions: CameraOptions {
    public let countdownDigits: Int
    public let timeInMillisecondsPerCountdownDigit: Int
    public let textForManualCapture: String
    public let textForState: (DocumentCameraState) -> String
    public let colorForState: (DocumentCameraState) -> CGColor

    public init(countdownDigits: Int = 2,
                timeInSecondsPerCountdownDigit: Int = 900,
                showDetectionBox: Bool = true,
                hideNavigationBar: Bool = true,
                showBackButton: Bool = true,
                autoCapture: Bool = true,
                bracketLengthInHorizontal: Int = 80,
                bracketLengthInVertical: Int = 50,
                defaultBracketMarginWidth: CGFloat = 0.5,
                defaultBracketMarginHeight: CGFloat = 0.6,
                textForState: @escaping (DocumentCameraState) -> String = { state in
                    switch state {
                    case .align: return "ALIGN"
                    case .moveCloser: return "MOVE CLOSER"
                    case .tooClose: return "TOO CLOSE"
                    case .steady: return "HOLD STEADY"
                    case .hold: return "HOLD"
                    case .capture: return "CAPTURING"
                    @unknown default: return ""
                    }
                },
                colorForState: @escaping (DocumentCameraState) -> CGColor = { state in
                    switch state {
                    case .align: return UIColor.black.cgColor
                    case .moveCloser: return UIColor.red.cgColor
                    case .tooClose: return UIColor.red.cgColor
                    case .steady: return UIColor.yellow.cgColor
                    case .hold: return UIColor.yellow.cgColor
                    case .capture: return UIColor.green.cgColor
                    @unknown default: return UIColor.black.cgColor
                    }
                },
                textForManualCapture: String = "ALIGN & TAP",
                textForCameraPaused: String = "CAMERA PAUSED",
                backButtonText: String = "BACK") {
        self.countdownDigits = countdownDigits
        self.timeInMillisecondsPerCountdownDigit = timeInSecondsPerCountdownDigit
        self.textForManualCapture = textForManualCapture
        self.textForState = textForState
        self.colorForState = colorForState
        super.init(hideNavigationBar: hideNavigationBar,
                   showBackButton: showBackButton,
                   placeholderImageName: nil,
                   autoCapture: autoCapture,
                   showDetectionBox: showDetectionBox,
                   bracketLengthInHorizontal: bracketLengthInHorizontal,
                   bracketLengthInVertical: bracketLengthInVertical,
                   defaultBracketMarginWidth: defaultBracketMarginWidth,
                   defaultBracketMarginHeight: defaultBracketMarginHeight,
                   textForCameraPaused: textForCameraPaused,
                   backButtonText: backButtonText)
    }
}


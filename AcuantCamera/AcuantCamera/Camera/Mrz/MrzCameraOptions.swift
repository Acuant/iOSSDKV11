//
//  MrzCameraOptions.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 13/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import UIKit
import Foundation

@objc public enum MrzCameraState: Int {
    case none, align, moveCloser, tooClose, reposition, good, captured
}

@objcMembers public class MrzCameraOptions: CameraOptions {
    public let textForState: (MrzCameraState) -> String
    public let colorForState: (MrzCameraState) -> CGColor

    public init(showDetectionBox: Bool = true,
                hideNavigationBar: Bool = true,
                showBackButton: Bool = true,
                bracketLengthInHorizontal: Int = 50,
                bracketLengthInVertical: Int = 40,
                defaultBracketMarginWidth: CGFloat = 0.58,
                defaultBracketMarginHeight: CGFloat = 0.63,
                placeholderImageName: String? = "Passport_placement_Overlay",
                textForState: @escaping (MrzCameraState) -> String = { state in
                    switch state {
                    case .none, .align: return ""
                    case .moveCloser: return "Move Closer"
                    case .tooClose: return "Too Close!"
                    case .good: return "Reading MRZ"
                    case .captured: return "Captured"
                    case .reposition: return "Reposition"
                    @unknown default: return ""
                    }
                },
                colorForState: @escaping (MrzCameraState) -> CGColor = { state in
                    switch state {
                    case .none, .align: return UIColor.black.cgColor
                    case .moveCloser: return UIColor.red.cgColor
                    case .tooClose: return UIColor.red.cgColor
                    case .good: return UIColor.yellow.cgColor
                    case .captured: return UIColor.green.cgColor
                    case .reposition: return UIColor.red.cgColor
                    @unknown default: return UIColor.black.cgColor
                    }
                },
                textForCameraPaused: String = "CAMERA PAUSED",
                backButtonText: String = "BACK") {
        self.textForState = textForState
        self.colorForState = colorForState
        super.init(hideNavigationBar: hideNavigationBar,
                   showBackButton: showBackButton,
                   placeholderImageName: placeholderImageName,
                   showDetectionBox: showDetectionBox,
                   bracketLengthInHorizontal: bracketLengthInHorizontal,
                   bracketLengthInVertical: bracketLengthInVertical,
                   defaultBracketMarginWidth: defaultBracketMarginWidth,
                   defaultBracketMarginHeight: defaultBracketMarginHeight,
                   textForCameraPaused: textForCameraPaused,
                   backButtonText: backButtonText)
    }
}


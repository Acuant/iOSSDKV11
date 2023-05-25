//
//  BarcodeCameraOptions.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 7/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

@objc public enum BarcodeCameraState: Int {
    case align
    case capturing
}

@objcMembers public class BarcodeCameraOptions: CameraOptions {
    public let waitTimeAfterCapturingInSeconds: Int
    public let timeoutInSeconds: Int
    public let textForState: (BarcodeCameraState) -> String
    public let colorForState: (BarcodeCameraState) -> CGColor

    public init(hideNavigationBar: Bool = true,
                showBackButton: Bool = true,
                waitTimeAfterCapturingInSeconds: Int = 1,
                timeoutInSeconds: Int = 20,
                placeholderImageName: String? = "barcode_placement_overlay",
                textForState: @escaping (BarcodeCameraState) -> String = { state in
                    switch state {
                    case .align: return "CAPTURE BARCODE"
                    case .capturing: return "CAPTURING"
                    @unknown default: return ""
                    }
                },
                colorForState: @escaping (BarcodeCameraState) -> CGColor = { state in
                    switch state {
                    case .align: return UIColor.white.cgColor
                    case .capturing: return UIColor.green.cgColor
                    @unknown default: return UIColor.white.cgColor
                    }
                },
                textForCameraPaused: String = "CAMERA PAUSED",
                backButtonText: String = "BACK") {
        self.waitTimeAfterCapturingInSeconds = waitTimeAfterCapturingInSeconds
        self.timeoutInSeconds = timeoutInSeconds
        self.textForState = textForState
        self.colorForState = colorForState
        super.init(hideNavigationBar: hideNavigationBar,
                   showBackButton: showBackButton,
                   placeholderImageName: placeholderImageName,
                   bracketLengthInHorizontal: 0,
                   bracketLengthInVertical: 0,
                   textForCameraPaused: textForCameraPaused,
                   backButtonText: backButtonText)
    }
}

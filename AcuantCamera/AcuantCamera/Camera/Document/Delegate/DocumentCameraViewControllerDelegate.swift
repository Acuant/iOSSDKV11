//
//  CameraCaptureDelegate.swift
//  CameraSDK
//
//  Created by Tapas Behera on 1/24/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import AcuantCommon

@objc public protocol DocumentCameraViewControllerDelegate {
    func onCaptured(image: Image, barcodeString: String?)
}

//
//  CameraCaptureDelegate.swift
//  CameraSDK
//
//  Created by Tapas Behera on 1/24/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//
import Foundation
import AcuantImagePreparation
import AcuantCommon

@objc public protocol CameraCaptureDelegate {
    func setCapturedImage(image:Image, barcodeString:String?)
}

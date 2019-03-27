//
//  CameraCaptureDelegate.swift
//  CameraSDK
//
//  Created by Tapas Behera on 1/24/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//
import AcuantImagePreparation
import AcuantCommon
public protocol CameraCaptureDelegate {
    func setCapturedImage(image:Image, barcodeString:String?)
}


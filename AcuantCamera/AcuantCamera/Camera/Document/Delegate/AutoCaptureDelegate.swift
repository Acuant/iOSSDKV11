//
//  AutoCaptureDelegate.swift
//  AcuantCamera
//
//  Created by Sergey Matsev on 11/13/20.
//  Copyright © 2020 Acuant. All rights reserved.
//

import Foundation

@objc public protocol AutoCaptureDelegate {
    func getAutoCapture() -> Bool
    func setAutoCapture(autoCapture: Bool)
}

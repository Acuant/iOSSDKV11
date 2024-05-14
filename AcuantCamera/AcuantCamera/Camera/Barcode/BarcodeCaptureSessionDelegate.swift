//
//  BarcodeCaptureSessionDelegate.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 9/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import Foundation

@objc public protocol BarcodeCaptureSessionDelegate: AnyObject {
    func captured(barcode: String?)
}

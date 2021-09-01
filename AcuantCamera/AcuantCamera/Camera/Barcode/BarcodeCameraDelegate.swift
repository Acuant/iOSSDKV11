//
//  BarcodeCameraDelegate.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 9/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

@objc public protocol BarcodeCameraDelegate: AnyObject {
    func captured(barcode: String?)
}

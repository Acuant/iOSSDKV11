//
//  MrzCameraViewControllerDelegate.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 13/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import Foundation

@objc public protocol MrzCameraViewControllerDelegate: AnyObject {
    func onCaptured(mrz: AcuantMrzResult?)
}

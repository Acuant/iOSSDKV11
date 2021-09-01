//
//  UIInterfaceOrientationExtensions.swift
//  AcuantFaceCapture
//
//  Created by Federico Nicoli on 13/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit
import AVFoundation

extension UIInterfaceOrientation {

    var faceCaptureVideoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }

}

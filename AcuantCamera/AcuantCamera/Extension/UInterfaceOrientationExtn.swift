//
//  UInterfaceOrientationExtn.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 8/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

import AVFoundation
import UIKit

extension UIInterfaceOrientation {

    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }

}

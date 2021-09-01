//
//  UIWindowExtensions.swift
//  AcuantFaceCapture
//
//  Created by Federico Nicoli on 13/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit

extension UIWindow {

    var faceCaptureInterfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 13, *) {
            return windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

}

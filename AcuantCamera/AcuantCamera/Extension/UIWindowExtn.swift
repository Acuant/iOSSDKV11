//
//  UIWindowExtn.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 8/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

import UIKit

extension UIWindow {

    var interfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 13, *) {
            return windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

}

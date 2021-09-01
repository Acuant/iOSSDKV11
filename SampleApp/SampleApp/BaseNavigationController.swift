//
//  BaseNavigationController.swift
//  SampleApp
//
//  Created by Federico Nicoli on 13/8/21.
//  Copyright © 2021 com.acuant. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    private static let defaultSupportedOrientations: UIInterfaceOrientationMask =
        UIDevice.current.userInterfaceIdiom == .pad
        ? .all
        : .allButUpsideDown

    private var supportedOrientation = defaultSupportedOrientations
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return supportedOrientation
        }
        set {
            supportedOrientation = newValue
        }
    }

    func resetToSupportedOrientations() {
        supportedInterfaceOrientations = BaseNavigationController.defaultSupportedOrientations
    }
}

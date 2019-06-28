//
//  AppOrientationDelegate.swift
//  AcuantCamera
//
//  Created by John Moon local on 6/18/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation
import UIKit

public protocol AppOrientationDelegate{
    func onAppOrientationLockChanged(mode: UIInterfaceOrientationMask)
}

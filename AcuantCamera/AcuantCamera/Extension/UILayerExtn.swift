//
//  UILayerExtn.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 9/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

import UIKit

extension CALayer {

    func rotate(angle: CGFloat) {
        transform = CATransform3DMakeRotation(CGFloat(angle / 180.0 * .pi), 0.0, 0.0, 1.0)
    }

}

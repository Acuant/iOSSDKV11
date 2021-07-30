//
//  CameraAlertView.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 10/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

import UIKit

class CameraAlertView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = .black
        alpha = 0.5
        isUserInteractionEnabled = false
    }

}

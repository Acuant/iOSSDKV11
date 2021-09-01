//
//  AlertView.swift
//  AcuantFaceCapture
//
//  Created by Federico Nicoli on 13/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit

class AlertView: UIView {

    private let textLabel = UILabel()

    init(frame: CGRect, text: String) {
        textLabel.text = text
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        addSubview(textLabel)
        textLabel.textColor = .white
        textLabel.font = textLabel.font.withSize(18)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            textLabel.widthAnchor.constraint(equalToConstant: 300),
            textLabel.heightAnchor.constraint(equalToConstant: 50),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        backgroundColor = .black
        alpha = 0.8
        isUserInteractionEnabled = false
    }

}

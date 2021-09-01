//
//  CameraPlacementImageOverlay.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 9/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

import Foundation

class DocumentPlaceholderLayer: CALayer {

    private var image: UIImage!
    
    init(image: UIImage, bounds: CGRect) {
        self.image = image
        super.init()
        setup(bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    private func setup(_ bounds: CGRect) {
        setFrame(frame: bounds)
        contents = image.cgImage
    }
    
    func setFrame(frame: CGRect) {
        self.frame = CGRect(x: frame.size.width / 2 - image.size.width / 2,
                            y: frame.size.height / 2 - image.size.height / 2,
                            width: image.size.width,
                            height: image.size.height)
    }
    
}

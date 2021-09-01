//
//  ImagePlaceholder.swift
//  AcuantFaceCapture
//
//  Created by Federico Nicoli on 12/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit

class ImagePlaceholderLayer: CALayer {
    
    private var image: UIImage!
    
    init(image: UIImage, bounds: CGRect) {
        self.image = image
        super.init()
        opacity = 0.6
        contents = image.cgImage
        setFrame(bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    func setFrame(_ frame: CGRect) {
        self.frame = CGRect(x: frame.size.width / 2 - image.size.width / 4,
                            y: frame.size.height / 2 - image.size.height / 4,
                            width: image.size.width / 2,
                            height: image.size.height / 2)
    }
}

//
//  FaceCaptureResult.swift
//  AcuantFaceCapture
//
//  Created by Federico Nicoli on 7/12/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit

@objcMembers public class FaceCaptureResult: NSObject {
    public let image: UIImage
    public let jpegData: Data
    
    init(image: UIImage, jpegData: Data) {
        self.image = image
        self.jpegData = jpegData
    }
}

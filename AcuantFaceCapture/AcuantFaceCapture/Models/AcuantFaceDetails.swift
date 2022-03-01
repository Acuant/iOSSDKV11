//
//  AcuantFaceDetails.swift
//  AcuantFaceCapture
//
//  Created by John Moon local on 1/22/20.
//  Copyright © 2020 Acuant. All rights reserved.
//

import Foundation
import UIKit

@objcMembers public class AcuantFaceDetails : NSObject{
    public let image : UIImage?
    public let state: AcuantFaceState
    public let faceRect : CGRect?
    public let cleanAperture : CGRect?
    
    public init(state: AcuantFaceState, image: UIImage? = nil, cleanAperture : CGRect? = nil, faceRect : CGRect? = nil){
        self.image = image
        self.state = state
        self.faceRect = faceRect
        self.cleanAperture = cleanAperture
    }
}

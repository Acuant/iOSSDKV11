//
//  AcuantFaceState.swift
//  AcuantFaceCapture
//
//  Created by John Moon local on 1/22/20.
//  Copyright © 2020 Acuant. All rights reserved.
//

import Foundation

@objc public enum AcuantFaceState: Int{
    case NONE
    case FACE_TOO_CLOSE
    case FACE_MOVED
    case FACE_TOO_FAR
    case FACE_GOOD_DISTANCE
    case FACE_NOT_IN_FRAME
    case FACE_HAS_ANGLE
}

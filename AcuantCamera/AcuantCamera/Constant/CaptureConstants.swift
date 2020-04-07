//
//  CaptureConstants.swift
//  AcuantCamera
//
//  Created by Tapas Behera on 3/4/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

import Foundation

@objcMembers public class CaptureConstants : NSObject{
    
    public static let CAMERA_PREVIEW_LONGER_SIDE_STANDARD = 3840
    public static let CAMERA_PRIVEW_LARGER_DOCUMENT_DPI_RATIO = 0.094167
    public static let CAMERA_PRIVEW_SMALLER_DOCUMENT_DPI_RATIO = 0.15625

    public static let ASPECT_RATIO_ID1 = 1.59
    public static let ASPECT_RATIO_ID3 = 1.42
    public static let ASPECT_RATIO_THRESHOLD = 5.0 // 5%
    
    public static let MANDATORY_RESOLUTION_THRESHOLD_DEFAULT = 600
    public static let MANDATORY_RESOLUTION_THRESHOLD_SMALL = 400
    public static let MANDATORY_RESOLUTION_THRESHOLD_DEFAULT_OLD_PHONES = 170
    public static let MANDATORY_RESOLUTION_THRESHOLD_SMALL_OLD_PHONES = 120
    
    public static let NO_DOCUMENT_DPI_THRESHOLD = 20
    public static let SMALL_DOCUMENT_DPI_THRESHOLD = 20
    public static let SHARPNESS_THRESHOLD = 50
    public static let GLARE_THRESHOLD = 50
}

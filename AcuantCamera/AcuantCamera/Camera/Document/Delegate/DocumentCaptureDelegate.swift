//
//  DocumentCaptureDelegate.swift

//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//
import Foundation
import AcuantCommon
import UIKit

@objc public protocol DocumentCaptureDelegate {
    func readyToCapture()
    func documentCaptured(image:UIImage, barcodeString:String?)
}

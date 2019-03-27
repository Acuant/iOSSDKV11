//
//  DocumentCaptureDelegate.swift

//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//
import AcuantCommon
import UIKit

public protocol DocumentCaptureDelegate {
    func readyToCapture()
    func documentCaptured(image:UIImage, barcodeString:String?)
    func didStartCaptureSession()
}

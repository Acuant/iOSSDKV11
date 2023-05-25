//
//  DocumentCaptureSessionDelegate.swift

//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit

@objc public protocol DocumentCaptureSessionDelegate {
    func readyToCapture()
    func documentCaptured(image: UIImage, barcodeString: String?)
}

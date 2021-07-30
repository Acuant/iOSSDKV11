//
//  CameraPreviewView.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 2/7/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPreviewView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer.")
        }
        return layer
    }

    private var _accessibleElements: [UIAccessibilityElement]?
    private var accessibleElements: [UIAccessibilityElement]? {
        get {
            if let elements = _accessibleElements {
                return elements
            }
            
            _accessibleElements = [UIAccessibilityElement]()
            if let messageElement = createTextLayerAccesibilityElement() {
                _accessibleElements?.append(messageElement)
            }
            return _accessibleElements
        }
        set {
            _accessibleElements = newValue
        }
    }

    init(frame: CGRect, captureSession: AVCaptureSession) {
        super.init(frame: frame)
        videoPreviewLayer.session = captureSession
        videoPreviewLayer.frame = frame
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createTextLayerAccesibilityElement() -> UIAccessibilityElement? {
        guard let cameraTextLayer = layer.sublayers?.first(where: { $0 is CameraTextView }) as? CameraTextView else {
            return nil
        }

        let accessiblityElement = UIAccessibilityElement(accessibilityContainer: self)
        accessiblityElement.isAccessibilityElement = true
        accessiblityElement.accessibilityFrame = convert(cameraTextLayer.frame, to: nil)
        accessiblityElement.accessibilityTraits = .updatesFrequently
        accessiblityElement.accessibilityValue = cameraTextLayer.string as? String
        cameraTextLayer.accessibilityElement = accessiblityElement
        return accessiblityElement
    }
    
    override func accessibilityElementCount() -> Int {
        return accessibleElements?.count ?? 0
    }
    
    override func accessibilityElement(at index: Int) -> Any? {
        return accessibleElements?[index]
    }
    
    override func index(ofAccessibilityElement element: Any) -> Int {
        return accessibleElements?.firstIndex(of: element as! UIAccessibilityElement) ?? 0
    }
    
    func clearAccessibilityElements() {
        accessibleElements = nil
    }
    
}

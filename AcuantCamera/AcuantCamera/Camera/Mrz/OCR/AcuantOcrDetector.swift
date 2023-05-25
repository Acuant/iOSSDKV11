//
//  AcuantOcrDetector.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation

public class AcuantOcrDetector {
    let tesseract: Tesseract
        
    public init() {
        tesseract = Tesseract(language: .custom("OCRB"), engineMode: .tesseractOnly)
        tesseract.configure {
            set(.allowlist, value: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<")
            set(.pageSegmentationMode, value: String.integer(3)) //automatic page segmentation
        }
    }
    
    public func detect(image: UIImage) -> String? {
        if case .success(let recognizedText) = tesseract.performOCR(on: image) {
            return recognizedText
        }
        return nil
    }
}

extension Tesseract.Variable {
  static let pageSegmentationMode = Tesseract.Variable("tessedit_pageseg_mode")
}

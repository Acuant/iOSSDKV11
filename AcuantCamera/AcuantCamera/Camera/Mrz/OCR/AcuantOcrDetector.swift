//
//  AcuantOcrDetector.swift
//  AcuantNFC
//
//  Created by John Moon local on 10/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import TesseractOCR

public class AcuantOcrDetector {
    let tesseract: G8Tesseract?
    var isInitalized = false
        
    public init(){
        tesseract = G8Tesseract(language: "OCRB")
        if let success = tesseract {
            isInitalized = true
            success.pageSegmentationMode = .auto
            success.charWhitelist = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<"
        }
    }
    
    public func detect(image: UIImage) -> String? {
        if self.isInitalized {
            self.tesseract!.image = image
            if self.tesseract!.recognize() {
                return self.tesseract!.recognizedText!
            } else {
                return nil
            }
        }
        return nil
    }
}

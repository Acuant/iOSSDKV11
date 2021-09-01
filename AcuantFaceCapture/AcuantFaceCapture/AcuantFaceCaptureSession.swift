//
//  AcuantFaceCaptureSession.swift
//  AcuantFaceCapture
//
//  Created by John Moon local on 1/22/20.
//  Copyright © 2020 Acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objcMembers public class AcuantFaceCaptureSession :AVCaptureSession, AVCaptureVideoDataOutputSampleBufferDelegate{
    private let callback : ((AcuantFaceDetails) -> ())
    private let captureDevice: AVCaptureDevice
    private var openEyeFrame : UIImage? = nil
    private let context = CIContext()
    
    private var processing : Bool = false
    
    private let MOVEMENT_TRESHOLD: CGFloat = 25
    private var lastFacePosition: CGRect? = nil
    
    let serialQueue = DispatchQueue(label: "serialQueue")
    
    public init(captureDevice: AVCaptureDevice, callback : @escaping ((AcuantFaceDetails) -> ())){
        self.captureDevice = captureDevice
        self.callback = callback
    }
    
    public func start() {
        processing = false
        
        if(captureDevice.isFocusModeSupported(.continuousAutoFocus)) {
            try? captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            self.addInput(input)
        } catch _ as NSError {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        if(!self.canAddOutput(videoOutput)){
            return
        }
        self.addOutput(videoOutput)
        videoOutput.setSampleBufferDelegate(self, queue: serialQueue)
        super.startRunning()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.global().async {
            if(self.processing){
                return
            }
            
            self.processing = true
            
            let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
            let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as? [CIImageOption : Any])
            let options: [String : Any] = [CIDetectorImageOrientation: self.exifOrientation(orientation: UIDevice.current.orientation),CIDetectorEyeBlink: true,CIDetectorAccuracy:CIDetectorAccuracyHigh]
            let allFeatures = faceDetector?.features(in: ciImage, options: options)
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            _ = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, originIsAtTopLeft: false)
            let fdesc = CMSampleBufferGetFormatDescription(sampleBuffer)
            let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc!, originIsAtTopLeft: false /*originIsTopLeft == false*/);
            
            guard let features = allFeatures else {
                self.processing = false
                self.callback(AcuantFaceDetails(state: AcuantFaceState.NONE))
                return
            }
            if(allFeatures?.count==0){
                self.processing = false
                self.callback(AcuantFaceDetails(state: AcuantFaceState.NONE))
                return
            }
            
            for feature in features {
                if let faceFeature = feature as? CIFaceFeature {
                    // get the clean aperture
                    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
                    // that represents image data valid for display.
                    let faceType = self.isGoodSizeFace(face: faceFeature, previewLayerSize: cleanAperture.size)
                    
                    if(faceType == AcuantFaceState.FACE_GOOD_DISTANCE && !faceFeature.leftEyeClosed && !faceFeature.rightEyeClosed){
                        if let out_image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer){
                            self.openEyeFrame = self.rotateImage(image: out_image, radians: .pi/2)
                        }
                    }
                    self.callback(AcuantFaceDetails(state: faceType, image: self.openEyeFrame, cleanAperture: cleanAperture, faceRect: faceFeature.bounds))
                    
                    self.processing = false
                }
            }
        }
    }
    
    func rotateImage(image: UIImage, radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: image.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        image.draw(in: CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func isGoodSizeFace(face: CIFaceFeature, previewLayerSize: CGSize) -> AcuantFaceState {
        let bounds = UIScreen.main.bounds
        let width = bounds.size.width
        let height = bounds.size.height
        let screenRatio = max(width, height) / min(width, height)
        let cameraRatio = max(previewLayerSize.width, previewLayerSize.height) / min(previewLayerSize.width, previewLayerSize.height)

        var TOO_CLOSE_THRESH: CGFloat = 0.235 * screenRatio / cameraRatio
        var TOO_FAR_THRESH: CGFloat = 0.385 * screenRatio / cameraRatio
        let ratioToEdges = 1 - face.bounds.height / previewLayerSize.height
        
        let isLandscape = face.bounds.height / face.bounds.width > 1
        if isLandscape {
            TOO_CLOSE_THRESH = 0.5 * screenRatio / cameraRatio
            TOO_FAR_THRESH = 0.55 * screenRatio / cameraRatio
        }

        if isFaceInBound(facePosition: face.bounds, previewLayerSize: previewLayerSize) {
            return AcuantFaceState.FACE_NOT_IN_FRAME
        } else if ratioToEdges < TOO_CLOSE_THRESH {
            return AcuantFaceState.FACE_TOO_CLOSE
        } else if ratioToEdges > TOO_FAR_THRESH {
            return AcuantFaceState.FACE_TOO_FAR
        } else if doesFaceHaveAngle(hasAnglePosition: face.hasFaceAngle, faceAngle: face.faceAngle) {
            return AcuantFaceState.FACE_HAS_ANGLE
        } else if didFaceMove(facePosition: face.bounds) {
            return AcuantFaceState.FACE_MOVED
        } else {
            return AcuantFaceState.FACE_GOOD_DISTANCE
        }
    }
    
    func doesFaceHaveAngle(hasAnglePosition:Bool, faceAngle: Float) -> Bool{
        return hasAnglePosition && (faceAngle > 10 || faceAngle < -10)
    }
    
    func isFaceInBound(facePosition : CGRect, previewLayerSize:CGSize) -> Bool {
        return (facePosition.origin.x < 0 || facePosition.origin.x + facePosition.width > previewLayerSize.width) ||
            (facePosition.origin.y < 0 || facePosition.origin.y + facePosition.height > previewLayerSize.height)
    }
    
    
    func didFaceMove(facePosition : CGRect) -> Bool{
        var isFaceMoved = false
        if(self.lastFacePosition != nil){
            isFaceMoved =
                self.lastFacePosition!.origin.x > facePosition.origin.x + MOVEMENT_TRESHOLD ||
                self.lastFacePosition!.origin.x < facePosition.origin.x - MOVEMENT_TRESHOLD ||
                self.lastFacePosition!.origin.y > facePosition.origin.y + MOVEMENT_TRESHOLD ||
                self.lastFacePosition!.origin.x < facePosition.origin.x - MOVEMENT_TRESHOLD
        }
        self.lastFacePosition = facePosition
        return isFaceMoved
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}



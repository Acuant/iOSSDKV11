//
//  CaptureSession.swift

//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantCommon
import AcuantImagePreparation

@objcMembers public class DocumentCaptureSession :AVCaptureSession,AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate{

    let stillImageOutput = AVCapturePhotoOutput()
    var croppedFrame : Image? = nil
    var stringValue : String? = nil
    var captureDevice: AVCaptureDevice?
    var shouldShowBorder = true
    weak var delegate : DocumentCaptureDelegate? = nil
    
    private let context = CIContext()
    private let DEFAULT_FRAME_THRESHOLD = 1
    private let FAST_FRAME_THRESHOLD = 3
    private var frameCounter = 0
    private var autoCapture = true
    private var captureEnabled = true
    private var captured = false
    private var cropping = false
    private var input : AVCaptureDeviceInput? = nil
    private var videoOutput : AVCaptureVideoDataOutput? = nil
    private var captureMetadataOutput : AVCaptureMetadataOutput? = nil
    private var devicePreviewResolutionLongerSide = CaptureConstants.CAMERA_PREVIEW_LONGER_SIDE_STANDARD
    weak private var frameDelegate:FrameAnalysisDelegate? = nil
    
    public class func getDocumentCaptureSession(delegate:DocumentCaptureDelegate?, frameDelegate: FrameAnalysisDelegate,autoCapture:Bool, captureDevice:AVCaptureDevice?)-> DocumentCaptureSession{
        return DocumentCaptureSession().getDocumentCaptureSession(delegate: delegate!, frameDelegate: frameDelegate,autoCapture: autoCapture,  captureDevice: captureDevice)
    }
    
    private func getDocumentCaptureSession(delegate:DocumentCaptureDelegate?, frameDelegate:FrameAnalysisDelegate,autoCapture:Bool, captureDevice: AVCaptureDevice?)->DocumentCaptureSession{
        self.delegate = delegate
        self.captureDevice = captureDevice
        self.frameDelegate = frameDelegate
        self.autoCapture = autoCapture
        return self;
    }
    
    public func enableCapture(){
        self.captureEnabled = true
        self.captured = true
        self.capturePhoto()
        DispatchQueue.main.async{
            self.delegate?.readyToCapture()
        }
    }
    
    public func start() {
        self.automaticallyConfiguresApplicationAudioSession = false
           self.usesApplicationAudioSession = false
           if(self.captureDevice?.isFocusModeSupported(.continuousAutoFocus))! {
               try? self.captureDevice?.lockForConfiguration()
               self.captureDevice?.focusMode = .continuousAutoFocus
               self.captureDevice?.unlockForConfiguration()
           }
           do {
               self.input = try AVCaptureDeviceInput(device: self.captureDevice!)
               if(self.canAddInput(self.input!)){
                   self.addInput(self.input!)
               }
           } catch _ as NSError {
               return
           }
           
           self.sessionPreset = AVCaptureSession.Preset.photo

           if let formatDescription = self.captureDevice?.activeFormat.formatDescription {
               let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
               self.devicePreviewResolutionLongerSide = max(Int(dimensions.width),Int(dimensions.height))
           }
           
           self.videoOutput = AVCaptureVideoDataOutput()
           self.videoOutput?.alwaysDiscardsLateVideoFrames = true
           let frameQueue = DispatchQueue(label: "com.acuant.frame.queue",qos:.userInteractive,attributes:.concurrent)
           self.videoOutput?.setSampleBufferDelegate(self, queue: frameQueue)
           if(self.canAddOutput(self.videoOutput!)){
               self.addOutput(self.videoOutput!)
           }
            if(self.canAddOutput(self.stillImageOutput)){
                self.stillImageOutput.isLivePhotoCaptureEnabled = false
              self.addOutput(self.stillImageOutput)
          }

           /* Check for metadata */
           self.captureMetadataOutput = AVCaptureMetadataOutput()
           let metadataQueue = DispatchQueue(label: "com.acuant.metadata.queue",qos:.userInteractive,attributes:.concurrent)
           self.captureMetadataOutput?.setMetadataObjectsDelegate(self, queue: metadataQueue)
           if (self.canAddOutput(self.captureMetadataOutput!)) {
               self.addOutput(self.captureMetadataOutput!)
               self.captureMetadataOutput?.metadataObjectTypes = [.pdf417]
           }
        self.startRunning()
    }
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let frameQueue = DispatchQueue(label: "com.acuant.image.queue",attributes:.concurrent)
        frameQueue.async {
            let frame = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            if(frame != nil && self.captured == false){
                if(self.cropping || self.captured){
                    return
                }
                if(self.autoCapture == false){
                    return
                }
                self.cropping = true
                self.croppedFrame = self.detectImage(image: frame!)
                let frameSize = frame!.size

                DispatchQueue.main.async{ [weak self] in
                    if(self != nil) {
                        let croppedImage = self!.croppedFrame
                        var frameResult: FrameResult
                        var scaledPoints : Array<CGPoint> = Array<CGPoint>()
                        var MANDATORY_RESOLUTION_THRESHOLD = CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_DEFAULT
                        
                        if(croppedImage != nil){
                            if(croppedImage!.points.count == 4 && self!.shouldShowBorder){
                                croppedImage!.points.forEach{ point in
                                    var scaled: CGPoint = CGPoint()
                                    scaled.x = point.x/frameSize.width as CGFloat
                                    scaled.y = point.y/frameSize.height  as CGFloat
                                    scaledPoints.append(scaled)
                                }
                            }
                            
                            if(croppedImage!.isPassport){
                                MANDATORY_RESOLUTION_THRESHOLD = Int(Double(frameSize.width) * CaptureConstants.CAMERA_PRIVEW_LARGER_DOCUMENT_DPI_RATIO)
                                
                            }else{
                                MANDATORY_RESOLUTION_THRESHOLD = Int(Double(frameSize.width) * CaptureConstants.CAMERA_PRIVEW_SMALLER_DOCUMENT_DPI_RATIO)
                            }
                        }
                        
                        if(croppedImage == nil || croppedImage!.error?.errorCode == AcuantErrorCodes.ERROR_CouldNotCrop || (croppedImage!.dpi) < CaptureConstants.NO_DOCUMENT_DPI_THRESHOLD){
                            frameResult = FrameResult.NO_DOCUMENT
                            self!.frameCounter = 0
                        }else if(croppedImage!.error?.errorCode == AcuantErrorCodes.ERROR_LowResolutionImage && (croppedImage!.dpi) < MANDATORY_RESOLUTION_THRESHOLD){
                            frameResult = FrameResult.SMALL_DOCUMENT
                            self!.frameCounter = 0
                        }else if(croppedImage!.isCorrectAspectRatio == false){
                            frameResult = FrameResult.BAD_ASPECT_RATIO
                            self!.frameCounter = 0
                        }else{
                            frameResult = FrameResult.GOOD_DOCUMENT
                        }
                        self!.frameDelegate?.onFrameAvailable(frameResult: frameResult, points: scaledPoints)
                        self!.cropping = false
                    }
                }
            }
        }
    }
    
    public func getFrameMatchThreshold(cropDuration: Double) -> Int{
        switch(cropDuration){
            case 0..<0.8:
                return FAST_FRAME_THRESHOLD
            default:
                return DEFAULT_FRAME_THRESHOLD
        }
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            if(readableObject.stringValue == nil){
                return
            }
            self.stringValue = readableObject.stringValue
        }
    }
    
    func found2DBarcode(code: String,image:Image!) {
        if(self.captured == false){
            self.capturePhoto()
        }
    }
    
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Check if there is any error in capturing
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }
        
        // Check if the pixel buffer could be converted to image data
        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer")
            return
        }
        
        // Check if UIImage could be initialized with image data
        guard let capturedImage = UIImage.init(data: imageData , scale: 1.0) else {
            print("Fail to convert image data to UIImage")
            return
        }
        
        DispatchQueue.main.async{
            self.captureDevice = nil
            self.stopRunning()
            self.delegate?.documentCaptured(image: capturedImage, barcodeString:self.stringValue)
            self.delegate = nil
        }
    }
    
    
    func capturePhoto() {
        let photoSetting = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSetting.isAutoStillImageStabilizationEnabled = true
        self.stillImageOutput.capturePhoto(with: photoSetting, delegate: self)
    }
    
    func detectImage(image:UIImage)->Image?{
        let croppingData  = CroppingData()
        croppingData.image = image
        
        let croppedImage = AcuantImagePreparation.detect(data: croppingData)
        return croppedImage
    }
}

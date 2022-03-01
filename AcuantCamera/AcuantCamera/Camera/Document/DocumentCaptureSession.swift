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

@objcMembers public class DocumentCaptureSession: AVCaptureSession {

    let stillImageOutput = AVCapturePhotoOutput()
    var croppedFrame: Image?
    var stringValue: String?
    var captureDevice: AVCaptureDevice?
    var shouldShowBorder = true
    weak var delegate: DocumentCaptureDelegate?
    
    private let context = CIContext()
    private let DEFAULT_FRAME_THRESHOLD = 1
    private let FAST_FRAME_THRESHOLD = 3
    private let TOO_SLOW_FOR_AUTO_CAPTURE = 130
    private let VIDEO_ZOOM_FACTOR = 1.6
    private var autoCapture = true
    weak private var autoCaptureDelegate: AutoCaptureDelegate?
    private var captureEnabled = true
    private var captured = false
    private var cropping = false
    private var times = [-1, -1, -1]
    private var finishedTest = false
    private var input: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput!
    private var captureMetadataOutput: AVCaptureMetadataOutput!
    private var devicePreviewResolutionLongerSide = CaptureConstants.CAMERA_PREVIEW_LONGER_SIDE_STANDARD
    weak private var frameDelegate: FrameAnalysisDelegate?
    
    public override init() {
        super.init()
        if #available(iOS 13.0, *) {
            stillImageOutput.maxPhotoQualityPrioritization = .quality
        }
    }
    
    public class func getDocumentCaptureSession(delegate: DocumentCaptureDelegate?,
                                                frameDelegate: FrameAnalysisDelegate,
                                                autoCaptureDelegate: AutoCaptureDelegate,
                                                captureDevice: AVCaptureDevice?) -> DocumentCaptureSession {
        return DocumentCaptureSession().getDocumentCaptureSession(delegate: delegate!,
                                                                  frameDelegate: frameDelegate,
                                                                  autoCaptureDelegate: autoCaptureDelegate,
                                                                  captureDevice: captureDevice)
    }
    
    private func getDocumentCaptureSession(delegate: DocumentCaptureDelegate?,
                                           frameDelegate: FrameAnalysisDelegate,
                                           autoCaptureDelegate: AutoCaptureDelegate,
                                           captureDevice: AVCaptureDevice?) -> DocumentCaptureSession {
        self.delegate = delegate
        self.captureDevice = captureDevice
        self.frameDelegate = frameDelegate
        self.autoCaptureDelegate = autoCaptureDelegate
        self.autoCapture = autoCaptureDelegate.getAutoCapture()
        return self
    }
    
    public func enableCapture() {
        self.captureEnabled = true
        self.captured = true
        self.capturePhoto()
        DispatchQueue.main.async {
            self.delegate?.readyToCapture()
        }
    }
    
    public func start() {
        guard let videoDevice = captureDevice else {
            return
        }

        self.automaticallyConfiguresApplicationAudioSession = false
        self.usesApplicationAudioSession = false
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.unlockForConfiguration()
        }

        self.input = try? AVCaptureDeviceInput(device: videoDevice)
        if let input = self.input, self.canAddInput(input) {
            self.addInput(input)
        }

        self.sessionPreset = .photo

        let formatDescription = videoDevice.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        self.devicePreviewResolutionLongerSide = max(Int(dimensions.width), Int(dimensions.height))
           
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        let frameQueue = DispatchQueue(label: "com.acuant.frame.queue", qos: .userInteractive, attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        if self.canAddOutput(self.videoOutput){
            self.addOutput(self.videoOutput)
        }
        if self.canAddOutput(self.stillImageOutput) {
            self.stillImageOutput.isLivePhotoCaptureEnabled = false
            self.addOutput(self.stillImageOutput)
        }

        self.captureMetadataOutput = AVCaptureMetadataOutput()
        let metadataQueue = DispatchQueue(label: "com.acuant.metadata.queue", qos: .userInteractive, attributes: .concurrent)
        self.captureMetadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        if self.canAddOutput(self.captureMetadataOutput) {
           self.addOutput(self.captureMetadataOutput)
           self.captureMetadataOutput.metadataObjectTypes = [.pdf417]
        }
        self.startRunning()
        try? videoDevice.lockForConfiguration()
        if videoDevice.maxAvailableVideoZoomFactor >= VIDEO_ZOOM_FACTOR {
            videoDevice.videoZoomFactor = VIDEO_ZOOM_FACTOR
        }
        videoDevice.unlockForConfiguration()
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func getFrameResult(basedOn detectedImage: Image?,
                                frame: UIImage,
                                smallerDocumentDPIRatio: Double,
                                largerDocumentDPIRatio: Double) -> (frameResult: FrameResult, scaledPoints: [CGPoint]) {
        guard let croppedFrame = detectedImage else {
            return (.NO_DOCUMENT, [])
        }

        let frameSize = frame.size
        var scaledPoints = [CGPoint]()
        var resolutionThreshold = CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_DEFAULT

        if self.isDocumentAligned(croppedFrame.points), self.shouldShowBorder {
            croppedFrame.points.forEach{ point in
                var scaled: CGPoint = CGPoint()
                scaled.x = point.x/frameSize.width as CGFloat
                scaled.y = point.y/frameSize.height  as CGFloat
                scaledPoints.append(scaled)
            }
        }

        if croppedFrame.isPassport {
            resolutionThreshold = Int(Double(frameSize.width) * largerDocumentDPIRatio)
        } else {
            resolutionThreshold = Int(Double(frameSize.width) * smallerDocumentDPIRatio)
        }

        if croppedFrame.error?.errorCode == AcuantErrorCodes.ERROR_CouldNotCrop || croppedFrame.dpi < CaptureConstants.NO_DOCUMENT_DPI_THRESHOLD {
            return (.NO_DOCUMENT, scaledPoints)
        } else if croppedFrame.error?.errorCode == AcuantErrorCodes.ERROR_LowResolutionImage, croppedFrame.dpi < resolutionThreshold {
            return (.SMALL_DOCUMENT, scaledPoints)
        } else if !croppedFrame.isCorrectAspectRatio {
            return (.BAD_ASPECT_RATIO, scaledPoints)
        } else if CGRect(points: croppedFrame.points) != nil {
            return (.GOOD_DOCUMENT, scaledPoints)
        } else {
            return (.DOCUMENT_NOT_IN_FRAME, scaledPoints)
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
    
    func capturePhoto() {
        let photoSetting = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        if #available(iOS 13.0, *) {
            photoSetting.photoQualityPrioritization = .quality
        } else {
            photoSetting.isAutoStillImageStabilizationEnabled = true
        }
        self.stillImageOutput.capturePhoto(with: photoSetting, delegate: self)
    }

    func detectImage(image: UIImage) -> Image? {
        let detectData  = DetectData.newInstance(image: image)

        let croppedImage = ImagePreparation.detect(detectData: detectData)
        return croppedImage
    }

    private func isDocumentAligned(_ points: [CGPoint]) -> Bool {
        guard points.count == 4 else {
            return false
        }

        return abs(points[1].x - points[3].x) > abs(points[1].y - points[3].y)
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension DocumentCaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = imageFromSampleBuffer(sampleBuffer: sampleBuffer), !captured, !cropping, autoCapture else {
            return
        }

        cropping = true
        let startTime = CACurrentMediaTime()
        croppedFrame = detectImage(image: frame)
        let elapsed = CACurrentMediaTime() - startTime

        if !finishedTest {
            for i in 0 ..< self.times.count {
                if self.times[i] == -1 {
                    self.times[i] = Int(elapsed * 1000)
                    if i == times.count - 1 {
                        break
                    } else {
                        cropping = false
                        return
                    }
                }
            }
        }

        if !times.contains(-1) {
            finishedTest = true
            if times.min() ?? TOO_SLOW_FOR_AUTO_CAPTURE + 10 > TOO_SLOW_FOR_AUTO_CAPTURE {
                autoCapture = false
                autoCaptureDelegate?.setAutoCapture(autoCapture: false)
                return
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let result = self.getFrameResult(basedOn: self.croppedFrame,
                                             frame: frame,
                                             smallerDocumentDPIRatio: CaptureConstants.CAMERA_PRIVEW_SMALLER_DOCUMENT_DPI_RATIO,
                                             largerDocumentDPIRatio: CaptureConstants.CAMERA_PRIVEW_LARGER_DOCUMENT_DPI_RATIO)
            self.frameDelegate?.onFrameAvailable(frameResult: result.frameResult, points: result.scaledPoints)
            self.cropping = false
        }
    }

}

//MARK: - AVCaptureMetadataOutputObjectsDelegate

extension DocumentCaptureSession: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let mrco = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = mrco.stringValue else {
            return
        }

        self.stringValue = stringValue
    }

}

//MARK: - AVCapturePhotoCaptureDelegate

extension DocumentCaptureSession: AVCapturePhotoCaptureDelegate {

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
        
        DispatchQueue.main.async {
            self.captureDevice = nil
            self.stopRunning()
            self.delegate?.documentCaptured(image: capturedImage, barcodeString: self.stringValue)
            self.delegate = nil
        }
    }

}

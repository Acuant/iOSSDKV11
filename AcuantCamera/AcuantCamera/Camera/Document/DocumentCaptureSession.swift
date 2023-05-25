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

@objcMembers public class DocumentCaptureSession: CameraCaptureSession {
    let stillImageOutput = AVCapturePhotoOutput()
    var croppedFrame: Image?
    var stringValue: String?
    var shouldShowBorder = true
    weak var delegate: DocumentCaptureSessionDelegate?
    weak var autoCaptureDelegate: AutoCaptureDelegate?
    weak var frameDelegate: FrameAnalysisDelegate?

    private let DEFAULT_FRAME_THRESHOLD = 1
    private let FAST_FRAME_THRESHOLD = 3
    private let TOO_SLOW_FOR_AUTO_CAPTURE = 130
    private var autoCapture = true
    
    private var captureEnabled = true
    private var captured = false
    private var cropping = false
    private var times = [-1, -1, -1]
    private var finishedTest = false
    private var input: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput!
    private var captureMetadataOutput: AVCaptureMetadataOutput!
    private var devicePreviewResolutionLongerSide = CaptureConstants.CAMERA_PREVIEW_LONGER_SIDE_STANDARD
    
    public init(captureDevice: AVCaptureDevice) {
        let queue = DispatchQueue(label: "com.acuant.document-capture-session", qos: .userInteractive)
        super.init(captureDevice: captureDevice, sessionQueue: queue)
    }
    
    override func onConfigurationBegan() {
        automaticallyConfiguresApplicationAudioSession = false
        usesApplicationAudioSession = false
        sessionPreset = .photo
        setFocusMode(captureDevice: captureDevice)
        add(captureDevice: captureDevice)
        if #available(iOS 13.0, *) {
            stillImageOutput.maxPhotoQualityPrioritization = .quality
        }

        let formatDescription = captureDevice.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        devicePreviewResolutionLongerSide = max(Int(dimensions.width), Int(dimensions.height))

        configureVideoOutput()
        configureImageOutput()
        configureMetadataOutput()
    }

    override func enableCapture() {
        captureEnabled = true
        captured = true
        capturePhoto()
        DispatchQueue.main.async {
            self.delegate?.readyToCapture()
        }
    }

    private func setFocusMode(captureDevice: AVCaptureDevice) {
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
    }

    private func add(captureDevice: AVCaptureDevice) {
        guard let input = try? AVCaptureDeviceInput(device: captureDevice), canAddInput(input) else {
            return
        }
        addInput(input)
    }

    private func configureVideoOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let frameQueue = DispatchQueue(label: "com.acuant.frame.queue", qos: .userInteractive, attributes: .concurrent)
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        if canAddOutput(videoOutput) {
            addOutput(videoOutput)
        }
    }

    private func configureImageOutput() {
        if canAddOutput(stillImageOutput) {
            stillImageOutput.isLivePhotoCaptureEnabled = false
            addOutput(stillImageOutput)
        }
    }

    private func configureMetadataOutput() {
        captureMetadataOutput = AVCaptureMetadataOutput()
        let metadataQueue = DispatchQueue(label: "com.acuant.metadata.queue", qos: .userInteractive, attributes: .concurrent)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        if canAddOutput(captureMetadataOutput) {
           addOutput(captureMetadataOutput)
           captureMetadataOutput.metadataObjectTypes = [.pdf417]
        }
    }

    private func getFrameResult(basedOn detectedImage: Image?,
                                frame: UIImage,
                                smallerDocumentDPIRatio: Double,
                                largerDocumentDPIRatio: Double) -> (frameResult: FrameResult, scaledPoints: [CGPoint]) {
        guard let croppedFrame = detectedImage else {
            return (.noDocument, [])
        }

        let frameSize = frame.size
        var scaledPoints = [CGPoint]()
        var resolutionThreshold = CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_DEFAULT

        if shouldShowBorder {
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

        let frameRect = CGRect(origin: CGPoint(x: 0, y: 0), size: frameSize).insetBy(dx: 15, dy: 15)
        let detectedRect = CGRect(points: croppedFrame.points)

        if croppedFrame.error?.errorCode == AcuantErrorCodes.ERROR_CouldNotCrop
            || croppedFrame.dpi < CaptureConstants.NO_DOCUMENT_DPI_THRESHOLD
            || !isDocumentAligned(croppedFrame.points) {
            return (.noDocument, scaledPoints)
        }   else if !croppedFrame.isCorrectAspectRatio {
            return (.badAspectRatio, scaledPoints)
        } else if croppedFrame.error?.errorCode == AcuantErrorCodes.ERROR_LowResolutionImage, croppedFrame.dpi < resolutionThreshold {
            return (.smallDocument, scaledPoints)
        } else if let rect = detectedRect, !frameRect.contains(rect) {
            return (.documentNotInFrame, scaledPoints)
        } else {
            return (.goodDocument, scaledPoints)
        }
    }
    
    public func getFrameMatchThreshold(cropDuration: Double) -> Int {
        switch cropDuration {
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
        stillImageOutput.capturePhoto(with: photoSetting, delegate: self)
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
        guard let frame = imageFrom(sampleBuffer: sampleBuffer), !captured, !cropping, autoCapture else {
            return
        }

        cropping = true
        let startTime = CACurrentMediaTime()
        croppedFrame = detectImage(image: frame)
        let elapsed = CACurrentMediaTime() - startTime

        if !finishedTest {
            for i in 0 ..< times.count {
                if times[i] == -1 {
                    times[i] = Int(elapsed * 1000)
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
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print("Fail to convert pixel buffer")
            return
        }

        guard let capturedImage = UIImage.init(data: imageData , scale: 1.0) else {
            print("Fail to convert image data to UIImage")
            return
        }

        DispatchQueue.main.async {
            self.stopRunning()
            self.delegate?.documentCaptured(image: capturedImage, barcodeString: self.stringValue)
            self.delegate = nil
        }
    }

}

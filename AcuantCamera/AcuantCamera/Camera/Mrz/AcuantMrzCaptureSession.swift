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

@objcMembers public class AcuantMrzCaptureSession: AVCaptureSession {
    private let captureDevice: AVCaptureDevice
    private let detector = AcuantOcrDetector()
    private let parser = AcuantMrzParser()
    private let context = CIContext()
    private let maxReadingAttempts = 7
    private let maxDistanceBetweenPoints = 100
    private var readingAttempts = 0
    private let defaultVideoZoomFactor = 1.6
    private var previousPoints = [CGPoint]()
    private var cropping = false
    private var callback: ((AcuantMrzCameraController.MrzCameraState, AcuantMrzResult?, Array<CGPoint>?) -> Void)?
    
    public init(captureDevice: AVCaptureDevice,
                userCallback: ((AcuantMrzCameraController.MrzCameraState, AcuantMrzResult?, Array<CGPoint>?) -> Void)? = nil) {
        self.captureDevice = captureDevice
        self.callback = userCallback
    }
    
    public func start() {
        self.automaticallyConfiguresApplicationAudioSession = false
        self.usesApplicationAudioSession = false
        self.sessionPreset = AVCaptureSession.Preset.photo

        self.setFocusMode()
        self.addCaptureDevice()
        self.addVideoOutput()
        self.startRunning()
        self.applyZoom()
    }
    
    private func setFocusMode() {
        if self.captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? self.captureDevice.lockForConfiguration()
            self.captureDevice.focusMode = .continuousAutoFocus
            self.captureDevice.unlockForConfiguration()
        }
    }
    
    private func addCaptureDevice() {
        do {
            let input = try AVCaptureDeviceInput(device: self.captureDevice)
            if self.canAddInput(input) {
                self.addInput(input)
            }
        } catch {
            return
        }
    }
    
    private func addVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let frameQueue = DispatchQueue(label: "com.acuant.frame.queue", qos: .userInteractive, attributes: .concurrent)
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        if self.canAddOutput(videoOutput) {
            self.addOutput(videoOutput)
        }
    }

    private func applyZoom() {
        if #available(iOS 15.0, *) {
            let zoomFactor = getRecommendedZoomFactor()
            try? captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = zoomFactor
            captureDevice.unlockForConfiguration()
        } else {
            try? captureDevice.lockForConfiguration()
            if captureDevice.maxAvailableVideoZoomFactor >= defaultVideoZoomFactor {
                captureDevice.videoZoomFactor = defaultVideoZoomFactor
            }
            captureDevice.unlockForConfiguration()
        }
    }

    @available(iOS 15.0, *)
    private func getRecommendedZoomFactor() -> Double {
        let deviceMinimumFocusDistance = Float(captureDevice.minimumFocusDistance)
        guard deviceMinimumFocusDistance != -1 else { return defaultVideoZoomFactor }

        let formatDimensions = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
        let rectOfInterestWidth = Float(formatDimensions.height) / Float(formatDimensions.width)
        let deviceFieldOfView = captureDevice.activeFormat.videoFieldOfView
        let minimumSubjectDistanceForDoc = minimumSubjectDistanceForDoc(fieldOfView: deviceFieldOfView,
                                                                        minimumDocSizeInMillimeters: 125,
                                                                        previewFillPercentage: rectOfInterestWidth)
        var zoomFactor = 0.0
        if minimumSubjectDistanceForDoc < deviceMinimumFocusDistance {
            let optimalZoomFactor = Double(deviceMinimumFocusDistance / minimumSubjectDistanceForDoc)
            if optimalZoomFactor <= captureDevice.maxAvailableVideoZoomFactor  {
                zoomFactor = optimalZoomFactor
            }
        } else if defaultVideoZoomFactor <= captureDevice.maxAvailableVideoZoomFactor {
            zoomFactor = defaultVideoZoomFactor
        }

        return zoomFactor
    }

    private func minimumSubjectDistanceForDoc(fieldOfView: Float, minimumDocSizeInMillimeters: Float, previewFillPercentage: Float) -> Float {
        let radians = degreesToRadians(fieldOfView / 2)
        let filledDocSize = minimumDocSizeInMillimeters / previewFillPercentage
        return filledDocSize / (2 * tan(radians))
    }

    private func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * Float.pi / 180
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func getScaledPoints(points: [CGPoint], frameSize: CGSize) -> [CGPoint] {
        var scaledPoints = [CGPoint]()
        
        points.forEach { point in
            var scaled: CGPoint = CGPoint()
            scaled.x = point.x/frameSize.width as CGFloat
            scaled.y = point.y/frameSize.height  as CGFloat
            scaledPoints.append(scaled)
        }
        return scaledPoints
    }
    
    private func getMrzState(points: [CGPoint],
                             imgSize: CGSize,
                             frameSize: CGSize,
                             mrzResult: AcuantMrzResult?) -> AcuantMrzCameraController.MrzCameraState {
        if accumulatedDistanceBetween(oldPoints: previousPoints, and: points) > maxDistanceBetweenPoints {
            readingAttempts = 0
        }

        if !self.isCorrectAspectRatio(size: imgSize) || self.isMrzTilted(points: points) || !self.isMrzAligned(points) {
            readingAttempts = 0
            return .Align
        } else if self.isMrzTooFar(size: imgSize, frameSize: frameSize) {
            readingAttempts = 0
            return .MoveCloser
        } else if self.isMrzTooClose(size: imgSize, frameSize: frameSize) {
            readingAttempts = 0
            return .TooClose
        } else  {
            if mrzResult != nil {
                return .Captured
            } else if readingAttempts < maxReadingAttempts {
                readingAttempts += 1
                return .Good
            } else {
                return .Reposition
            }
        }
    }
    
    private func executeOCRAndParseMrzResult(image: UIImage) -> AcuantMrzResult? {
        guard
            let mrz = self.detector.detect(image: image),
            let parsedMrz = self.parser.parseMrz(mrz: mrz),
            parsedMrz.checkSumResult1,
            parsedMrz.checkSumResult2,
            parsedMrz.checkSumResult3,
            parsedMrz.checkSumResult4,
            parsedMrz.checkSumResult5
        else {
            return nil
        }

        return parsedMrz
    }
    
    private func isMrzTooClose(size: CGSize, frameSize: CGSize) -> Bool {
        return max(size.width, size.height) >= 0.95 * max(frameSize.width, frameSize.height)
    }
    
    private func isMrzTooFar(size: CGSize, frameSize: CGSize) -> Bool {
        return max(size.width, size.height) <= 0.65 * max(frameSize.width, frameSize.height)
    }
    
    private func isCorrectAspectRatio(size: CGSize) -> Bool {
        let aspectRatio = size.width/size.height
        return (4...10 ~= aspectRatio)
    }
    
    private func isMrzTilted(points: [CGPoint]) -> Bool {
        let diff1 = self.getDistance(p1: points[0], p2: points[2])
        let diff2 = self.getDistance(p1: points[1], p2: points[3])
        let diff3 = abs(diff2 - diff1)
        return (diff3 > 9)
    }
    
    private func getDistance(p1: CGPoint, p2: CGPoint) -> Int {
        return Int(sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2)))
    }

    private func isMrzAligned(_ points: [CGPoint]) -> Bool {
        guard points.count == 4 else {
            return false
        }

        return abs(points[1].x - points[3].x) > abs(points[1].y - points[3].y)
    }

    public func stopCamera() {
        self.stopRunning()
    }

    func detectImage(image: UIImage) -> Image? {
        let detectData  = DetectData.newInstance(image: image)
        
        let croppedImage = ImagePreparation.cropMrz(detectData: detectData)
        return croppedImage
    }

    func accumulatedDistanceBetween(oldPoints: [CGPoint], and newPoints: [CGPoint]) -> Int {
        guard oldPoints.count == 4, newPoints.count == 4 else {
            return 0
        }

        var distance = 0
        for i in 0...3 {
            distance += getDistance(p1: oldPoints[i], p2: newPoints[i])
        }

        return distance
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension AcuantMrzCaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            !self.cropping,
            self.detector.isInitalized,
            let frame = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        else {
            return
        }

        self.cropping = true

        var scaledPoints = [CGPoint]()
        var state = AcuantMrzCameraController.MrzCameraState.None
        var result: AcuantMrzResult?

        if let croppedFrame = self.detectImage(image: frame),
           let img = croppedFrame.image {
            result = self.executeOCRAndParseMrzResult(image: img)
            state = self.getMrzState(points: croppedFrame.points, imgSize: img.size, frameSize: frame.size, mrzResult: result)
            scaledPoints = self.getScaledPoints(points: croppedFrame.points, frameSize: frame.size)
            previousPoints = croppedFrame.points
        }

        if let cb = self.callback {
            cb(state, result, scaledPoints)
        }
        self.cropping = false
    }
}

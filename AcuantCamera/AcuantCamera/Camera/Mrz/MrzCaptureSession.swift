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

@objcMembers public class MrzCaptureSession: CameraCaptureSession {
    private let detector = AcuantOcrDetector()
    private let parser = AcuantMrzParser()
    private let maxReadingAttempts = 7
    private let maxDistanceBetweenPoints = 100
    private var readingAttempts = 0
    private var previousPoints = [CGPoint]()
    private var cropping = false

    public weak var delegate: MrzCaptureSessionDelegate?

    public init(captureDevice: AVCaptureDevice) {
        let queue = DispatchQueue(label: "com.acuant.mrz-capture-session", qos: .userInteractive)
        super.init(captureDevice: captureDevice, sessionQueue: queue)
    }
    
    override func onConfigurationBegan() {
        automaticallyConfiguresApplicationAudioSession = false
        usesApplicationAudioSession = false
        sessionPreset = AVCaptureSession.Preset.photo
        setFocusMode()
        addCaptureDevice()
        addVideoOutput()
    }
    
    private func setFocusMode() {
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
    }
    
    private func addCaptureDevice() {
        if let input = try? AVCaptureDeviceInput(device: captureDevice), canAddInput(input) {
            addInput(input)
        }
    }
    
    private func addVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let frameQueue = DispatchQueue(label: "com.acuant.frame.queue", qos: .userInteractive, attributes: .concurrent)
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        if canAddOutput(videoOutput) {
            addOutput(videoOutput)
        }
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
                             mrzResult: AcuantMrzResult?) -> MrzCameraState {
        if accumulatedDistanceBetween(oldPoints: previousPoints, and: points) > maxDistanceBetweenPoints {
            readingAttempts = 0
        }

        if !isCorrectAspectRatio(size: imgSize) || isMrzTilted(points: points) || !isMrzAligned(points) {
            readingAttempts = 0
            return .align
        } else if isMrzTooFar(size: imgSize, frameSize: frameSize) {
            readingAttempts = 0
            return .moveCloser
        } else if isMrzTooClose(size: imgSize, frameSize: frameSize) {
            readingAttempts = 0
            return .tooClose
        } else  {
            if mrzResult != nil {
                return .captured
            } else if readingAttempts < maxReadingAttempts {
                readingAttempts += 1
                return .good
            } else {
                return .reposition
            }
        }
    }
    
    private func executeOCRAndParseMrzResult(image: UIImage) -> AcuantMrzResult? {
        guard
            let mrz = detector.detect(image: image),
            let parsedMrz = parser.parseMrz(mrz: mrz),
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
        let diff1 = getDistance(p1: points[0], p2: points[2])
        let diff2 = getDistance(p1: points[1], p2: points[3])
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

extension MrzCaptureSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard
            !cropping,
            let frame = imageFrom(sampleBuffer: sampleBuffer)
        else {
            return
        }

        cropping = true

        var scaledPoints = [CGPoint]()
        var state = MrzCameraState.none
        var result: AcuantMrzResult?

        if let croppedFrame = detectImage(image: frame),
           let img = croppedFrame.image {
            result = executeOCRAndParseMrzResult(image: img)
            state = getMrzState(points: croppedFrame.points, imgSize: img.size, frameSize: frame.size, mrzResult: result)
            scaledPoints = getScaledPoints(points: croppedFrame.points, frameSize: frame.size)
            previousPoints = croppedFrame.points
        }

        delegate?.onCaptured(state: state, result: result, points: scaledPoints)
        cropping = false
    }
}

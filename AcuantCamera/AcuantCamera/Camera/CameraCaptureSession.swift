//
//  CameraCaptureSession.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 12/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import Foundation
import AVFoundation

@objcMembers public class CameraCaptureSession: AVCaptureSession {
    let sessionQueue: DispatchQueue
    let captureDevice: AVCaptureDevice
    private let context = CIContext()
    private let defaultVideoZoomFactor = 1.6

    init(captureDevice: AVCaptureDevice, sessionQueue: DispatchQueue) {
        self.captureDevice = captureDevice
        self.sessionQueue = sessionQueue
    }

    public func start(completion: (() -> Void)? = nil) {
        sessionQueue.async {
            self.beginConfiguration()
            self.onConfigurationBegan()
            self.commitConfiguration()
            self.startRunning()
            self.applyZoom()
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    public func stop() {
        sessionQueue.async {
            self.stopRunning()
        }
    }

    func onConfigurationBegan() { }

    func enableCapture() { }

    func imageFrom(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
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
                                                                        minimumDocSizeInMillimeters: 85,
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

    private func minimumSubjectDistanceForDoc(fieldOfView: Float,
                                              minimumDocSizeInMillimeters: Float,
                                              previewFillPercentage: Float) -> Float {
        let radians = degreesToRadians(fieldOfView / 2)
        let filledDocSize = minimumDocSizeInMillimeters / previewFillPercentage
        return filledDocSize / (2 * tan(radians))
    }

    private func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * Float.pi / 180
    }
    
}

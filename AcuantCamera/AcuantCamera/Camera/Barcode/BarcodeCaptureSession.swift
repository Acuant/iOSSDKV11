//
//  BarcodeCaptureSession.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 5/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import AVFoundation

@objcMembers public class BarcodeCaptureSession: AVCaptureSession {

    private let sessionDispatchQueue = DispatchQueue(label: "com.acuant.barcode-session", qos: .userInteractive)
    private let captureMetadataOutput = AVCaptureMetadataOutput()
    private let captureVideoOutput = AVCaptureVideoDataOutput()
    private var captureDeviceInput: AVCaptureDeviceInput!
    private let captureDevice: AVCaptureDevice!
    private let defaultVideoZoomFactor = 1.6
    private weak var delegate: BarcodeCaptureDelegate?

    init(captureDevice: AVCaptureDevice, delegate: BarcodeCaptureDelegate) {
        self.captureDevice = captureDevice
        self.delegate = delegate
    }

    func start(completion: @escaping () -> ()) {
        sessionDispatchQueue.async {
            self.beginConfiguration()
            self.configureDeviceInput()
            self.configureMetadataOutput()
            self.commitConfiguration()
            self.startRunning()
            self.applyZoom()
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func stop() {
        sessionDispatchQueue.async {
            self.stopRunning()
        }
    }

    private func configureDeviceInput() {
        automaticallyConfiguresApplicationAudioSession = false
        usesApplicationAudioSession = false
        if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? captureDevice.lockForConfiguration()
            captureDevice.focusMode = .continuousAutoFocus
            captureDevice.unlockForConfiguration()
        }
        captureDeviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        if canAddInput(captureDeviceInput) {
            addInput(captureDeviceInput)
        }
    }

    private func configureMetadataOutput() {
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: sessionDispatchQueue)
        if canAddOutput(captureMetadataOutput) {
            addOutput(captureMetadataOutput)
            captureMetadataOutput.metadataObjectTypes = [.pdf417]
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

    private func minimumSubjectDistanceForDoc(fieldOfView: Float, minimumDocSizeInMillimeters: Float, previewFillPercentage: Float) -> Float {
        let radians = degreesToRadians(fieldOfView / 2)
        let filledDocSize = minimumDocSizeInMillimeters / previewFillPercentage
        return filledDocSize / (2 * tan(radians))
    }

    private func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * Float.pi / 180
    }

}

//MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeCaptureSession: AVCaptureMetadataOutputObjectsDelegate {

    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let mrco = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.captured(barcode: mrco.stringValue)
        }
    }

}

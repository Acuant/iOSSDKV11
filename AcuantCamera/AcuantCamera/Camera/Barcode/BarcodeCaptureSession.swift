//
//  BarcodeCaptureSession.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 5/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import AVFoundation

@objcMembers public class BarcodeCaptureSession: CameraCaptureSession {
    private let captureMetadataOutput = AVCaptureMetadataOutput()
    private var captureDeviceInput: AVCaptureDeviceInput!
    public weak var delegate: BarcodeCaptureSessionDelegate?

    public init(captureDevice: AVCaptureDevice) {
        let queue = DispatchQueue(label: "com.acuant.barcode-capture-session", qos: .userInteractive)
        super.init(captureDevice: captureDevice, sessionQueue: queue)
    }

    override func onConfigurationBegan() {
        configureDeviceInput()
        configureMetadataOutput()
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
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        if canAddOutput(captureMetadataOutput) {
            addOutput(captureMetadataOutput)
            captureMetadataOutput.metadataObjectTypes = [.pdf417]
        }
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

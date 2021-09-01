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

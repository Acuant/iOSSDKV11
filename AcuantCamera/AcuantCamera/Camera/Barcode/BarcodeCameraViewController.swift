//
//  BarcodeCameraViewController.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 5/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit
import AVFoundation

@objcMembers public class BarcodeCameraViewController: CameraViewController {
    private let barcodeOptions: BarcodeCameraOptions
    private var timeoutTimer: Timer?
    private var afterCaptureTimer: Timer?

    public weak var delegate: BarcodeCameraViewControllerDelegate?

    public init(options: BarcodeCameraOptions) {
        barcodeOptions = options
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        let captureSession = BarcodeCaptureSession(captureDevice: captureDevice)
        super.init(options: options, captureSession: captureSession)
        timeoutTimer = scheduleTimeoutTimer(options.timeoutInSeconds)
        captureSession.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        customizeImageLayer()
        customizeMessageLayer()
    }

    override func onCameraInterrupted() {
        messageLayer.string = options.textForCameraPaused
        imageLayer?.isHidden = true
    }

    override func onCameraInterruptionEnded() {
        imageLayer?.isHidden = false
        messageLayer.string = barcodeOptions.textForState(.align)
    }

    override func onBackTapped() {
        delegate?.onCaptured(barcode: nil)
    }

    override func onPreviewCreated() {
        cameraPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    private func customizeMessageLayer() {
        messageLayer.string = barcodeOptions.textForState(.align)
        messageLayer.foregroundColorDefault = barcodeOptions.colorForState(.align)
        messageLayer.foregroundColorCapture = barcodeOptions.colorForState(.capturing)
        messageLayer.backgroundColorCapture = UIColor.black.cgColor
        messageLayer.textSizeCapture = 30
    }

    private func customizeImageLayer() {
        imageLayer?.opacity = 0.4
    }

    private func scheduleTimeoutTimer(_ timeout: Int) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.afterCaptureTimer?.invalidate()
            self.navigationController?.popViewController(animated: true)
            self.delegate?.onCaptured(barcode: nil)
        }
    }

}

//MARK: - BarcodeCaptureDelegate

extension BarcodeCameraViewController: BarcodeCaptureSessionDelegate {

    public func captured(barcode: String?) {
        guard let barcode = barcode, afterCaptureTimer == nil else { return }

        messageLayer.string = barcodeOptions.textForState(.capturing)
        if let orientation = view.window?.interfaceOrientation, orientation.isPortrait {
            messageLayer.setVerticalCaptureSettings(frame: view.bounds)
        } else {
            messageLayer.setCaptureSettings(frame: view.bounds)
        }
        afterCaptureTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(barcodeOptions.waitTimeAfterCapturingInSeconds),
                                                 repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.timeoutTimer?.invalidate()
            self.navigationController?.popViewController(animated: true)
            self.delegate?.onCaptured(barcode: barcode)
        }
    }

}

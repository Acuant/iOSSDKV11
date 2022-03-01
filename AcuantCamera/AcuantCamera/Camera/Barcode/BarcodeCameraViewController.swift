//
//  BarcodeCameraViewController.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 5/8/21.
//  Copyright © 2021 Acuant. All rights reserved.
//

import UIKit
import AVFoundation

@objcMembers public class BarcodeCameraViewController: UIViewController {

    private var cameraPreviewView: CameraPreviewView!
    private var messageLayer: CameraTextView!
    private var barcodeLayer: DocumentPlaceholderLayer?
    private var alertView: CameraAlertView?
    private var captureSession: BarcodeCaptureSession!

    private var options: CameraOptions!
    private var timeoutTimer: Timer?
    private var afterCaptureTimer: Timer?
    private var isNavigationBarHidden = false

    private weak var delegate: BarcodeCameraDelegate?

    override public var prefersStatusBarHidden: Bool {
        true
    }

    public init(options: CameraOptions, delegate: BarcodeCameraDelegate) {
        self.options = options
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        messageLayer = createMessageLayer(holdColor: options.colorHold, capturingColor: options.colorCapturing)
        barcodeLayer = createBarcodeLayer()
        timeoutTimer = scheduleTimeoutTimer(options.digitsToShow)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handleNavigationBarVisibility()
        addDeviceOrientationObserver()
        addCaptureSessionObservers()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        attachSession()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        detachSession()
        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(isNavigationBarHidden, animated: false)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }

            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation)
        })
    }

    private func createMessageLayer(holdColor: CGColor, capturingColor: CGColor) -> CameraTextView {
        let messageLayer = CameraTextView()
        messageLayer.string = NSLocalizedString("acuant_camera_capture_barcode", comment: "")
        messageLayer.foregroundColorDefault = holdColor
        messageLayer.foregroundColorCapture = capturingColor
        messageLayer.backgroundColorCapture = UIColor.black.cgColor
        messageLayer.textSizeCapture = 30
        messageLayer.defaultWidth = 320
        messageLayer.defaultHeight = 40
        messageLayer.captureWidth = 320
        messageLayer.captureHeight = 40
        return messageLayer
    }

    private func createBarcodeLayer() -> DocumentPlaceholderLayer? {
        guard let barcodeImage = getPlaceholderImage() else {
            return nil
        }

        let barcodeLayer = DocumentPlaceholderLayer(image: barcodeImage, bounds: view.frame)
        barcodeLayer.opacity = 0.4
        return barcodeLayer
    }

    private func getPlaceholderImage() -> UIImage? {
        if let image = UIImage(named: "barcode_placement_overlay",
                               in: Bundle(for: BarcodeCameraViewController.self),
                               compatibleWith: nil) {
            return image
        } else if let bundlePath = Bundle(for: BarcodeCameraViewController.self).path(forResource: "AcuantCameraAssets",
                                                                                    ofType: "bundle"),
                  let bundle = Bundle(path: bundlePath), let image = UIImage(named: "barcode_placement_overlay",
                                                                             in: bundle,
                                                                             compatibleWith: nil) {
            return image
        }
        return nil
    }

    private func scheduleTimeoutTimer(_ timeout: Int) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout), repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.afterCaptureTimer?.invalidate()
            self.navigationController?.popViewController(animated: true)
            self.delegate?.captured(barcode: nil)
        }
    }

    private func handleNavigationBarVisibility() {
        isNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(options.hideNavigationBar, animated: false)
    }

    private func addNavigationBackButton() {
        let backButton = UIButton(frame: CGRect(x: 0, y: UIScreen.main.heightOfSafeArea() * 0.065, width: 90, height: 40))

        var attribs: [NSAttributedString.Key: Any?] = [:]
        attribs[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 18)
        attribs[NSAttributedString.Key.foregroundColor] = UIColor.white
        attribs[NSAttributedString.Key.baselineOffset] = 4

        let str = NSMutableAttributedString(string: "BACK", attributes: attribs as [NSAttributedString.Key: Any])
        backButton.setAttributedTitle(str, for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.isOpaque = true
        backButton.imageView?.contentMode = .scaleAspectFit

        view.addSubview(backButton)
    }

    @objc private func backTapped(_ sender: Any) {
        delegate?.captured(barcode: nil)
        navigationController?.popViewController(animated: true)
    }

    private func attachSession() {
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        captureSession = BarcodeCaptureSession(captureDevice: captureDevice, delegate: self)
        cameraPreviewView = CameraPreviewView(frame: view.bounds, captureSession: captureSession)
        cameraPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill

        if let barcodeLayer = barcodeLayer {
            cameraPreviewView.layer.addSublayer(barcodeLayer)
        }
        messageLayer.setFrame(frame: view.frame)
        cameraPreviewView.layer.addSublayer(messageLayer)
        view.addSubview(cameraPreviewView)

        if options.showBackButton {
            addNavigationBackButton()
        }

        captureSession.start {
            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation)
        }
    }

    private func detachSession() {
        captureSession.stop()
        cameraPreviewView.removeFromSuperview()
    }

    private func rotateCameraPreview(to interfaceOrientation: UIInterfaceOrientation?) {
        guard let connection = cameraPreviewView.videoPreviewLayer.connection,
              connection.isVideoOrientationSupported,
              let orientation = interfaceOrientation else {
            return
        }

        cameraPreviewView.frame = view.bounds
        connection.videoOrientation = orientation.videoOrientation ?? .portrait
        cameraPreviewView.clearAccessibilityElements()

        if orientation.isLandscape {
            messageLayer.transform = CATransform3DIdentity
            messageLayer.setFrame(frame: view.bounds)
            barcodeLayer?.transform = CATransform3DIdentity
            barcodeLayer?.setFrame(frame: view.bounds)
        } else {
            if CATransform3DIsIdentity(messageLayer.transform) {
                messageLayer.rotate(angle: 90)
            }
            if let barcodeLayer = barcodeLayer, CATransform3DIsIdentity(barcodeLayer.transform) {
                barcodeLayer.setFrame(frame: view.bounds)
                barcodeLayer.rotate(angle: 90)
            }
            messageLayer.setVerticalDefaultSettings(frame: view.bounds)
        }
        cameraPreviewView.videoPreviewLayer.removeAllAnimations()
    }

    private func addDeviceOrientationObserver() {
        guard let orientations = Bundle.main.infoDictionary?[.kUISupportedInterfaceOrientations] as? [String],
              orientations.count == 1,
              orientations[0] == .kUIInterfaceOrientationPortrait else {
            return
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.deviceDidRotate),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    private func addCaptureSessionObservers() {
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self, self.alertView == nil else { return }

            self.messageLayer.string = NSLocalizedString("acuant_camera_paused", comment: "")
            self.barcodeLayer?.isHidden = true
            let alertView = CameraAlertView(frame: self.view.bounds)
            self.view.addSubview(alertView)
            self.view.bringSubviewToFront(alertView)
            self.alertView = alertView
        }

        NotificationCenter.default.addObserver(forName: .AVCaptureSessionInterruptionEnded,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }

            self.alertView?.removeFromSuperview()
            self.barcodeLayer?.isHidden = false
            self.alertView = nil
            self.messageLayer.string = NSLocalizedString("acuant_camera_capture_barcode", comment: "")
        }
    }

    @objc private func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation.isLandscape {
            if currentOrientation == UIDeviceOrientation.landscapeLeft {
                messageLayer.rotate(angle: -270)
                barcodeLayer?.rotate(angle: -270)
            } else if currentOrientation == UIDeviceOrientation.landscapeRight {
                messageLayer.rotate(angle: 270)
                barcodeLayer?.rotate(angle: 270)
            }
        }
    }

}

//MARK: - BarcodeCaptureDelegate

extension BarcodeCameraViewController: BarcodeCaptureDelegate {

    public func captured(barcode: String?) {
        guard let barcode = barcode, afterCaptureTimer == nil else { return }

        if let orientation = view.window?.interfaceOrientation, orientation.isPortrait {
            messageLayer.setVerticalCaptureSettings(frame: view.bounds)
        } else {
            messageLayer.setCaptureSettings(frame: view.bounds)
        }
        messageLayer.string = NSLocalizedString("acuant_camera_capturing", comment: "")
        afterCaptureTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(options.timeInMsPerDigit/1000),
                             repeats: false) { [weak self] _ in
            guard let self = self else { return }

            self.timeoutTimer?.invalidate()
            self.navigationController?.popViewController(animated: true)
            self.delegate?.captured(barcode: barcode)
        }
    }

}

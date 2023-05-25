//
//  CameraViewController.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 12/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import UIKit
import AVFoundation

@objcMembers public class CameraViewController: UIViewController {
    var lastDeviceOrientation: UIDeviceOrientation!
    var cameraPreviewView: CameraPreviewView!
    var messageLayer: CameraTextLayer!
    var cornerLayer: CameraCornerLayer!
    var detectionBoxLayer: CameraRectangularLayer!
    var imageLayer: CameraImageLayer?
    var alertView: CameraAlertView?
    var isNavigationHidden = false
    var backButton: UIButton!

    let options: CameraOptions
    let captureSession: CameraCaptureSession

    override public var prefersStatusBarHidden: Bool {
        return true
    }

    init(options: CameraOptions, captureSession: CameraCaptureSession) {
        self.options = options
        self.captureSession = captureSession
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        lastDeviceOrientation = UIDevice.current.orientation
        handleNavigationBarVisibility()
        createCameraLayers()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addDeviceOrientationObserver()
        addCaptureSessionObservers()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
        NotificationCenter.default.removeObserver(self)
        navigationController?.setNavigationBarHidden(isNavigationHidden, animated: false)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }

            let newFrame = CGRect(origin: self.view.frame.origin, size: size)
            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation, frame: newFrame)
        })
    }

    private func handleNavigationBarVisibility() {
        isNavigationHidden = navigationController?.isNavigationBarHidden ?? false
        navigationController?.setNavigationBarHidden(options.hideNavigationBar, animated: false)
    }

    private func createCameraLayers() {
        messageLayer = CameraTextLayer()
        cornerLayer = CameraCornerLayer(bracketLengthInHorizontal: options.bracketLengthInHorizontal,
                                        bracketLengthInVertical: options.bracketLengthInVertical,
                                        defaultBracketMarginWidth: options.defaultBracketMarginWidth,
                                        defaultBracketMarginHeight: options.defaultBracketMarginHeight)
        detectionBoxLayer = CameraRectangularLayer()
        if let image = getPlaceholderImage() {
            imageLayer = CameraImageLayer(image: image, bounds: view.bounds)
        }
    }

    func getPlaceholderImage() -> UIImage? {
        guard let imageName = options.placeholderImageName else {
            return nil
        }

        if let image = UIImage(named: imageName) {
            return image
        } else if let image = UIImage(named: imageName,
                                      in: Bundle(for: CameraViewController.self),
                                      compatibleWith: nil) {
            return image
        } else if let bundlePath = Bundle(for: CameraViewController.self).path(forResource: "AcuantCameraAssets",
                                                                               ofType: "bundle"),
                  let bundle = Bundle(path: bundlePath), let image = UIImage(named: imageName,
                                                                             in: bundle,
                                                                             compatibleWith: nil) {
            return image
        }
        return nil
    }

    private func addDeviceOrientationObserver() {
        guard let orientations = Bundle.main.infoDictionary?[.kUISupportedInterfaceOrientations] as? [String],
              orientations.count == 1,
              orientations[0] == .kUIInterfaceOrientationPortrait else {
            return
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceDidRotate),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    @objc func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.current.orientation
        guard lastDeviceOrientation != currentOrientation, messageLayer != nil else {
            return
        }

        if currentOrientation.isLandscape {
            if currentOrientation == UIDeviceOrientation.landscapeLeft {
                messageLayer.rotate(angle: -270)
                imageLayer?.rotate(angle: -270)
            } else if currentOrientation == UIDeviceOrientation.landscapeRight {
                messageLayer.rotate(angle: 270)
                imageLayer?.rotate(angle: 270)
            }
            lastDeviceOrientation = currentOrientation
        }
    }

    private func addCaptureSessionObservers() {
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self, self.alertView == nil else { return }

            self.onCameraInterrupted()
            let alertView = CameraAlertView(frame: self.view.bounds)
            self.view.addSubview(alertView)
            self.view.bringSubviewToFront(alertView)
            self.alertView = alertView
        }

        NotificationCenter.default.addObserver(forName: .AVCaptureSessionInterruptionEnded,
                                               object: captureSession,
                                               queue: .main) { [weak self ] _ in
            guard let self = self else { return }

            self.alertView?.removeFromSuperview()
            self.alertView = nil
            self.onCameraInterruptionEnded()
        }
    }

    private func rotateCameraPreview(to interfaceOrientation: UIInterfaceOrientation?, frame: CGRect) {
        guard let connection = cameraPreviewView.videoPreviewLayer.connection,
              connection.isVideoOrientationSupported,
              let orientation = interfaceOrientation else {
            return
        }

        cameraPreviewView.frame = frame
        connection.videoOrientation = orientation.videoOrientation ?? .portrait
        cameraPreviewView.clearAccessibilityElements()

        if orientation.isLandscape {
            messageLayer.transform = CATransform3DIdentity
            messageLayer.setFrame(frame: frame)
            cornerLayer.setHorizontalDefaultCorners(frame: frame)
            imageLayer?.transform = CATransform3DIdentity
            imageLayer?.setFrame(frame: frame)
        } else {
            if CATransform3DIsIdentity(messageLayer.transform) {
                messageLayer.rotate(angle: 90)
            }

            if let imageLayer = self.imageLayer, CATransform3DIsIdentity(imageLayer.transform) {
                imageLayer.setFrame(frame: frame)
                imageLayer.rotate(angle: 90)
            }
            messageLayer.setVerticalDefaultSettings(frame: frame)
            cornerLayer.setFrame(frame: frame)
        }
        cameraPreviewView.videoPreviewLayer.removeAllAnimations()
    }
    
    private func startCamera() {
        cameraPreviewView = CameraPreviewView(frame: view.frame, captureSession: captureSession)
        onPreviewCreated()

        cameraPreviewView.layer.addSublayer(messageLayer)
        cameraPreviewView.layer.addSublayer(detectionBoxLayer)
        detectionBoxLayer.isHidden = !options.showDetectionBox
        cameraPreviewView.layer.addSublayer(cornerLayer)
        if let imageLayer = self.imageLayer {
            cameraPreviewView.layer.addSublayer(imageLayer)
        }
        view.addSubview(cameraPreviewView)

        captureSession.start {
            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation, frame: self.view.frame)
        }

        if options.showBackButton {
            addNavigationBackButton()
        }
    }

    private func stopCamera() {
        captureSession.stop()
        cameraPreviewView.removeFromSuperview()
    }

    private func addNavigationBackButton() {
        backButton = UIButton(frame: CGRect(x: 0, y: UIScreen.main.heightOfSafeArea() * 0.065, width: 90, height: 40))

        var attribs: [NSAttributedString.Key: Any?] = [:]
        attribs[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 18)
        attribs[NSAttributedString.Key.foregroundColor] = UIColor.white
        attribs[NSAttributedString.Key.baselineOffset] = 4

        let str = NSMutableAttributedString.init(string: options.backButtonText, attributes: attribs as [NSAttributedString.Key: Any])
        backButton.setAttributedTitle(str, for: .normal)
        backButton.addTarget(self, action: #selector(backTapped(_:)), for: .touchUpInside)
        backButton.isOpaque = true
        backButton.imageView?.contentMode = .scaleAspectFit
        view.addSubview(backButton)
    }

    @objc func backTapped(_ sender: Any) {
        onBackTapped()
        navigationController?.popViewController(animated: true)
    }

    func scalePoints(points: [CGPoint]) -> [CGPoint] {
        return [
            cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[0]),
            cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[1]),
            cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[2]),
            cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[3])
        ]
    }

    func onCameraInterrupted() { }

    func onCameraInterruptionEnded() { }

    func onBackTapped() { }

    func onPreviewCreated() { }
}

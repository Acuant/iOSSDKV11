//
//  CameraController.swift
//  SampleApp
//
//  Created by John Moon 2/20/20.
//  Copyright © 2020 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantImagePreparation
import AcuantCommon

@objcMembers public class AcuantMrzCameraController: UIViewController {
    @objc public enum MrzCameraState : Int {
        case None = 0, Align = 1, MoveCloser = 2, TooClose = 3, Good = 4, Captured = 5
    }
    
    var captureSession: AcuantMrzCaptureSession!
    var lastDeviceOrientation: UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var messageLayer: CameraTextView!
    var cornerLayer: CameraCornerOverlayView!
    var shapeLayer: CameraDocumentOverlayView!
    var imageLayer: DocumentPlaceholderLayer!
    var alertView: CameraAlertView?
    var backButton: UIButton!
    
    private var currentPoints: [CGPoint?] = [nil, nil, nil, nil]
    private var threshold = 25
    
    private var isNavigationHidden = false
    private var isCaptured = false
    
    public var options: CameraOptions!
    public var callback: ((AcuantMrzResult?) -> Void)?
    public var customDisplayMessage: ((MrzCameraState) -> String) = {
        state in
        switch state {
        case .None, .Align:
            return ""
        case .MoveCloser:
            return "Move Closer"
        case .TooClose:
            return "Too Close!"
        case .Good:
            return "Reading MRZ"
        case .Captured:
            return "Captured"
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationHidden = self.navigationController?.isNavigationBarHidden ?? false
        options = options ?? CameraOptions(
            bracketLengthInHorizontal: 50,
            bracketLengthInVertical: 40,
            defaultBracketMarginWidth: 0.58,
            defaultBracketMarginHeight: 0.63)
        self.navigationController?.setNavigationBarHidden(options.hideNavigationBar, animated: false)
        self.lastDeviceOrientation = UIDevice.current.orientation
        createCameraLayers()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCameraView()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addDeviceOrientationObserver()
        addCaptureSessionObservers()
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession?.stopRunning()
        }
        self.videoPreviewLayer?.removeFromSuperlayer()
        self.navigationController?.setNavigationBarHidden(self.isNavigationHidden, animated: false)
        NotificationCenter.default.removeObserver(self)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // TODO: Dispose of any resources that can be recreated.
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }

            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation)
        })
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

    private func addCaptureSessionObservers() {
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self, self.alertView == nil else { return }

            self.messageLayer.isHidden = false
            self.messageLayer.string = NSLocalizedString("acuant_camera_paused", comment: "")
            self.imageLayer.isHidden = true
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
            self.messageLayer.isHidden = true
            self.imageLayer.isHidden = false
        }
    }

    private func rotateCameraPreview(to interfaceOrientation: UIInterfaceOrientation?) {
        guard let connection = videoPreviewLayer.connection,
              connection.isVideoOrientationSupported,
              let orientation = interfaceOrientation else {
            return
        }

        videoPreviewLayer.frame = view.bounds
        connection.videoOrientation = orientation.videoOrientation ?? .portrait
        if orientation.isLandscape {
            cornerLayer.setHorizontalDefaultCorners(frame: view.bounds)
            messageLayer.transform = CATransform3DIdentity
            messageLayer.setFrame(frame: view.bounds)
            imageLayer.transform = CATransform3DIdentity
            imageLayer.setFrame(frame: view.bounds)
        } else {
            cornerLayer.setFrame(frame: view.bounds)

            if CATransform3DIsIdentity(messageLayer.transform) {
                messageLayer.rotate(angle: 90)
            }

            if CATransform3DIsIdentity(imageLayer.transform) {
                imageLayer.setFrame(frame: view.bounds)
                imageLayer.rotate(angle: 90)
            }
            messageLayer.setVerticalDefaultSettings(frame: view.bounds)
        }
        videoPreviewLayer.removeAllAnimations()
    }

    private var mrzResult: AcuantMrzResult?
    private var dotCount = 0
    private var counter: Timer?

    private func handleUi(color: CGColor, message: String = "", points: Array<CGPoint>? = nil, shouldShowOverlay: Bool = false){
        self.cornerLayer.setColor(color: color)
        
        if message.isEmpty {
            self.imageLayer?.isHidden = false
            self.messageLayer.isHidden = true
            if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
                self.cornerLayer.setHorizontalDefaultCorners(frame: self.view.frame)
            } else {
                self.cornerLayer.setDefaultCorners(frame: self.view.frame)
            }
            self.shapeLayer.hideBorder()
            self.counter?.invalidate()
            self.counter = nil
        } else {
            self.imageLayer?.isHidden = true
            self.messageLayer.isHidden = false
            self.messageLayer.string = message
            self.updateCorners(points: points)
            
            if shouldShowOverlay {
                self.shapeLayer.showBorder(color: color)
            } else {
                self.shapeLayer.hideBorder()
            }
        }
    }
    
    private func updateCorners(points: Array<CGPoint>?){
        if(points != nil && points?.count == 4){
            let convertedPoints = scalePoints(points: points!)
            let openSquarePath = UIBezierPath()
            openSquarePath.move(to: convertedPoints[0])
            openSquarePath.addLine(to: convertedPoints[1])
            openSquarePath.addLine(to: convertedPoints[2])
            openSquarePath.addLine(to: convertedPoints[3])
            openSquarePath.addLine(to: convertedPoints[0])
            
            self.shapeLayer.path = openSquarePath.cgPath
            self.cornerLayer.setCorners(point1: convertedPoints[0], point2: convertedPoints[1], point3: convertedPoints[2], point4: convertedPoints[3])
        }
    }

    func startCameraView() {
        let captureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        self.captureSession = AcuantMrzCaptureSession(captureDevice: captureDevice) { [weak self] (state, result, points) in
            DispatchQueue.main.async {
                guard let self = self, !self.captureSession.isInterrupted else { return }

                if self.videoPreviewLayer == nil ||
                    self.messageLayer == nil ||
                    self.videoPreviewLayer.isHidden ||
                    self.isCaptured {
                    return
                }

                if self.isOutsideView(points: points) {
                    self.mrzResult = nil
                    self.handleUi(color: self.options.colorBracketAlign, message: self.customDisplayMessage(.Align))
                } else {
                    if let parsedResut = result {
                        self.mrzResult = parsedResut
                    }
                    
                    let message = self.customDisplayMessage(state)

                    switch state {
                    case .None:
                        self.mrzResult = nil
                        self.handleUi(color: self.options.colorBracketAlign, message: message)
                    case .Align:
                        self.handleUi(color: self.options.colorBracketAlign, message: message)
                    case .MoveCloser:
                        self.handleUi(color: self.options.colorBracketCloser, message: message, points: points)
                    case .TooClose:
                        self.handleUi(color: self.options.colorBracketCloser, message: message, points: points)
                    case .Good, .Captured:
                        if self.mrzResult != nil {
                            self.isCaptured = true
                            self.handleUi(color: self.options.colorCapturing,
                                          message: self.customDisplayMessage(.Captured),
                                          points: points,
                                          shouldShowOverlay: true)
                            self.counter = Timer.scheduledTimer(timeInterval: 0.8,
                                                                target: self,
                                                                selector: #selector(self.exitTimer),
                                                                userInfo: nil,
                                                                repeats: false)
                        } else {
                            self.handleUi(color: self.options.colorBracketHold, message: message, points: points, shouldShowOverlay: true)
                        }
                    }
                }
            }
        }
        self.startSessionAndAddViews()
    }

    private func startSessionAndAddViews() {
        self.captureSession.start()
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoPreviewLayer.videoGravity = .resizeAspectFill

        createCameraLayers()

        self.videoPreviewLayer.addSublayer(self.shapeLayer)
        self.videoPreviewLayer.addSublayer(self.messageLayer)
        self.videoPreviewLayer.addSublayer(self.cornerLayer)
        self.videoPreviewLayer.addSublayer(self.imageLayer)
        self.view.layer.addSublayer(self.videoPreviewLayer)

        rotateCameraPreview(to: self.view.window?.interfaceOrientation)

        if self.options.showBackButton {
            addNavigationBackButton()
        }
    }

    private func createCameraLayers() {
        if self.messageLayer == nil {
            self.messageLayer = CameraTextView(autoCapture: options.autoCapture)
            self.messageLayer.isHidden = true
        }
        self.messageLayer.setFrame(frame: self.view.frame)
        if self.cornerLayer == nil {
            self.cornerLayer = CameraCornerOverlayView(options: options)
        }
        self.cornerLayer.setFrame(frame: self.view.frame)
        if shapeLayer == nil {
            shapeLayer = CameraDocumentOverlayView(options: options)
        }
        if imageLayer == nil {
            self.imageLayer = DocumentPlaceholderLayer(image: getPlaceholderImage() ?? UIImage(), bounds: self.view.frame)
        }
    }

    private func getPlaceholderImage() -> UIImage? {
        if self.options.defaultImageUrl.isEmpty {
            if let image = UIImage(named: "Passport_placement_Overlay",
                                   in: Bundle(for: AcuantMrzCameraController.self),
                                   compatibleWith: nil) {
                return image
            } else if let bundlePath = Bundle(for: AcuantMrzCameraController.self).path(forResource: "AcuantCameraAssets",
                                                                                        ofType: "bundle"),
                      let bundle = Bundle(path: bundlePath), let image = UIImage(named: "Passport_placement_Overlay",
                                                                                 in: bundle,
                                                                                 compatibleWith: nil) {
                return image
            }
        }
        return UIImage(named: self.options.defaultImageUrl)
    }
    
    public func exitTimer(){
        if let result = self.mrzResult{
            self.counter?.invalidate()
            self.captureSession.stopCamera()
            self.onMrzParsed(result: result)
        }
    }
    
    public func onMrzParsed(result: AcuantMrzResult) {
        if let cb = self.callback{
            cb(result)
        }
    }
    
    func isInRange(point: CGPoint) -> Bool{
        return (point.x >= 0 && point.x <= self.videoPreviewLayer.frame.width) && (point.y >= 0 && point.y <= self.videoPreviewLayer.frame.height)
    }
    
    func isOutsideView(points: Array<CGPoint>?) -> Bool {
        if(points != nil && points?.count == 4){
            let scaledPoints = scalePoints(points: points!)
            for i in scaledPoints {
                if(!isInRange(point: i)){
                    return true
                }
            }
        }
        return false
    }
    
    private func scalePoints(points: Array<CGPoint>) -> Array<CGPoint>{
        return [
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[0]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[1]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[2]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[3])
        ]
    }
    
    public func isDocumentMoved(newPoints: Array<CGPoint>) -> Bool{
        if(newPoints.count == self.currentPoints.count){
            for i in 0..<self.currentPoints.count {
                if(Int(abs(self.currentPoints[i]!.x - newPoints[i].x)) > threshold || Int(abs(self.currentPoints[i]!.y - newPoints[i].y)) > threshold ){
                    return true
                }
            }
        }
        return false
    }
    
    @objc func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.current.orientation
        guard self.lastDeviceOrientation != currentOrientation && self.messageLayer != nil else {
            return
        }

        if currentOrientation.isLandscape {
            if currentOrientation == UIDeviceOrientation.landscapeLeft {
                messageLayer.rotate(angle: -270)
                imageLayer.rotate(angle: -270)
            } else if currentOrientation == UIDeviceOrientation.landscapeRight {
                messageLayer.rotate(angle: 270)
                imageLayer.rotate(angle: 270)
            }
            self.lastDeviceOrientation = currentOrientation
        }
    }
    
    func addNavigationBackButton() {
        backButton = UIButton(frame: CGRect(x: 0, y: UIScreen.main.heightOfSafeArea()*0.065, width: 90, height: 40))
        
        var attribs : [NSAttributedString.Key : Any?] = [:]
        attribs[NSAttributedString.Key.font]=UIFont.systemFont(ofSize: 18)
        attribs[NSAttributedString.Key.foregroundColor]=UIColor.white
        attribs[NSAttributedString.Key.baselineOffset]=4
        
        let str = NSMutableAttributedString.init(string: "BACK", attributes: attribs as [NSAttributedString.Key : Any])
        backButton.setAttributedTitle(str, for: .normal)
        backButton.addTarget(self, action: #selector(backTapped(_:)), for: .touchUpInside)
        backButton.isOpaque=true
        backButton.imageView?.contentMode = .scaleAspectFit
        
        self.view.addSubview(backButton)
    }
    
    @objc func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        if let cb = self.callback{
            cb(nil)
        }
    }
}

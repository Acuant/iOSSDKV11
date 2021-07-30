//
//  CameraController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/6/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantImagePreparation
import AcuantCommon

@objcMembers public class DocumentCameraController: UIViewController {
    
    @objc public enum CameraState : Int {
        case Align = 0, MoveCloser = 1, Steady = 2, Hold = 3, Capture = 4
    }
    
    var captureWaitTime = 2
    var captureIntervalInSeconds = 0.9
    var captureSession: DocumentCaptureSession!
    var lastDeviceOrientation: UIDeviceOrientation!
    var cameraPreviewView: CameraPreviewView!
    var messageLayer: CameraTextView!
    var cornerLayer: CameraCornerOverlayView!
    var shapeLayer: CameraDocumentOverlayView!
    var alertView: CameraAlertView?
    var captured = false
    var hideNavBar = true
    var autoCapture = true
    var backButton: UIButton!
    
    private let context = CIContext()
    private var currentPoints: [CGPoint]?
    private var options: CameraOptions!
    weak private var cameraCaptureDelegate: CameraCaptureDelegate?
    
    private var currentState = FrameResult.NO_DOCUMENT
    private var captureTimerState = 0.0
    private var isHoldSteady = false
    private var holdSteadyTimer: Timer!
    
    private let captureTime = 1
    private let documentMovementThreshold = 25
    private let previewBoundsThreshold: CGFloat = -5

    private var currentStateCount = 0
    private var nextState = FrameResult.NO_DOCUMENT
    private var isNavigationHidden = false

    public class func getCameraController(delegate:CameraCaptureDelegate, cameraOptions: CameraOptions)->DocumentCameraController{
        let c = DocumentCameraController()
        c.cameraCaptureDelegate = delegate
        c.options = cameraOptions
        c.captureWaitTime = cameraOptions.digitsToShow
        c.autoCapture = cameraOptions.autoCapture
        c.hideNavBar = cameraOptions.hideNavigationBar
        c.captureIntervalInSeconds = Double(cameraOptions.timeInMsPerDigit)/Double(1000)
        return c
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationHidden = self.navigationController?.isNavigationBarHidden ?? false
        self.navigationController?.setNavigationBarHidden(hideNavBar, animated: false)

        createCameraLayers()

        self.lastDeviceOrientation = UIDevice.current.orientation

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchAction(_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc internal func touchAction(_ sender: UITapGestureRecognizer) {
        if !autoCapture, !captureSession.isInterrupted {
            self.captureSession.enableCapture()
        }
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
        self.cameraPreviewView?.removeFromSuperview()
        self.navigationController?.setNavigationBarHidden(self.isNavigationHidden, animated: false)
        NotificationCenter.default.removeObserver(self)
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
            self.alertView = nil
            if !self.autoCapture {
                self.messageLayer.string = NSLocalizedString("acuant_camera_manual_capture", comment: "")
            }
        }
    }

    func startCameraView() {
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        self.captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self,
                                                                               frameDelegate: self,
                                                                               autoCaptureDelegate: self,
                                                                               captureDevice: captureDevice)
        self.captureSession.start()
        cameraPreviewView = CameraPreviewView(frame: view.bounds, captureSession: captureSession)
        cameraPreviewView.videoPreviewLayer.videoGravity = UIDevice.current.userInterfaceIdiom == .pad
            ? .resizeAspectFill
            : .resizeAspect

        createCameraLayers()
                
        self.cameraPreviewView.layer.addSublayer(self.messageLayer)
        self.cameraPreviewView.layer.addSublayer(self.shapeLayer)
        self.cameraPreviewView.layer.addSublayer(self.cornerLayer)
        self.view.addSubview(cameraPreviewView)
        
        rotateCameraPreview(to: self.view.window?.interfaceOrientation)

        if self.options.showBackButton {
            addNavigationBackButton()
        }
    }

    private func createCameraLayers() {
        if self.messageLayer == nil {
            self.messageLayer = CameraTextView(autoCapture: autoCapture)
        }
        self.messageLayer.setFrame(frame: self.view.frame)
        if self.cornerLayer == nil {
            self.cornerLayer = CameraCornerOverlayView(options: options)
        }
        self.cornerLayer.setFrame(frame: self.view.frame)
        if shapeLayer == nil {
            shapeLayer = CameraDocumentOverlayView(options: options)
        }
    }

    public func rotateImage(image: UIImage) -> UIImage{
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            return image.rotate(radians: .pi/2)!
        }
        return image
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
            cornerLayer.setHorizontalDefaultCorners(frame: view.bounds)
        } else {
            if CATransform3DIsIdentity(messageLayer.transform) {
                messageLayer.rotate(angle: 90)
            }
            messageLayer.setVerticalDefaultSettings(frame: view.bounds)
            cornerLayer.setFrame(frame: view.bounds)
        }
        cameraPreviewView.videoPreviewLayer.removeAllAnimations()
    }

    private func setLookFromState(state: DocumentCameraController.CameraState) {
        switch state {
        case DocumentCameraController.CameraState.MoveCloser:
            self.setMessageDefaultSettings()
            self.setCornerSettings(color: self.options?.colorBracketCloser)
            self.shapeLayer.hideBorder()
        case DocumentCameraController.CameraState.Hold:
            self.setMessageCaptureSettings()
            self.cornerLayer.setColor(color: self.options?.colorBracketHold)
            self.shapeLayer.showBorder(color: self.options?.colorBracketHold)
        case DocumentCameraController.CameraState.Steady:
            self.setMessageDefaultSettings()
            self.cornerLayer.setColor(color: self.options?.colorBracketHold)
            self.shapeLayer.showBorder(color: self.options?.colorBracketHold)
        case DocumentCameraController.CameraState.Capture:
            self.setMessageCaptureSettings()
            self.cornerLayer.setColor(color: self.options?.colorBracketCapture)
            self.shapeLayer.showBorder(color: self.options?.colorBracketCapture)
        default://align
            self.setMessageDefaultSettings()
            self.setCornerSettings(color: self.options?.colorBracketAlign)
            self.shapeLayer.hideBorder()
        }
    }

    private func setCornerSettings(color: CGColor?) {
        cornerLayer.setColor(color: color)
        setSettings(landscapeSetting: cornerLayer.setHorizontalDefaultCorners,
                    portraitSetting: cornerLayer.setDefaultCorners)
    }

    private func setMessageDefaultSettings() {
        setSettings(landscapeSetting: messageLayer.setDefaultSettings,
                    portraitSetting: messageLayer.setVerticalDefaultSettings)
    }

    private func setMessageCaptureSettings() {
        setSettings(landscapeSetting: messageLayer.setCaptureSettings,
                    portraitSetting: messageLayer.setVerticalCaptureSettings)
    }

    private func setSettings(landscapeSetting: (CGRect) -> Void,
                             portraitSetting: (CGRect) -> Void) {
        guard let interfaceOrientation = view.window?.interfaceOrientation else {
            return
        }

        if interfaceOrientation.isLandscape {
            landscapeSetting(view.bounds)
        } else {
            portraitSetting(view.bounds)
        }
    }

    private func cancelCapture(state: CameraState, message: String){
        self.setLookFromState(state: state)
        self.messageLayer.string = message
        self.triggerHoldSteady()
        self.captureTimerState = 0.0
    }
    
    private func triggerHoldSteady(){
        if(!self.isHoldSteady && self.autoCapture){
            self.isHoldSteady = true
            holdSteadyTimer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(self.delayTimer(_:)),
                userInfo: nil,
                repeats: false)
        }
    }
    
    internal func delayTimer(_ timer: Timer){
        isHoldSteady = false
        holdSteadyTimer.invalidate()
    }
   
    private func getInterval(time: Double, duration: Double) -> Int{
        let current = CFAbsoluteTimeGetCurrent() - time
        return Int(current/duration)
    }
    
    private func handleInterval() {
        if captureTimerState == 0 {
            self.messageLayer.string = "\(self.captureWaitTime)..."
            self.captureTimerState = CFAbsoluteTimeGetCurrent()
        } else {
            let interval = getInterval(time: self.captureTimerState, duration: self.captureIntervalInSeconds)
            
            if interval >= self.captureWaitTime - 1 {
                self.captureSession.enableCapture()
            } else {
                self.messageLayer.string = "\(self.captureWaitTime - interval)..."
            }
        }
    }
    
    private func triggerCapture() {
        self.handleInterval()
    }
    
    public func isDocumentMoved(newPoints: Array<CGPoint>) -> Bool{
        if(self.currentPoints != nil && newPoints.count == self.currentPoints!.count){
            for i in 0..<self.currentPoints!.count {
                if(Int(abs(self.currentPoints![i].x - newPoints[i].x)) > documentMovementThreshold || Int(abs(self.currentPoints![i].y - newPoints[i].y)) > documentMovementThreshold ){
                    return true
                }
            }
        }
        return false
    }
    
    
    private func transitionState(state: CameraState, localString: String? = nil) {
        if (!autoCapture) {
            return
        }
        
        if(localString != nil){
            self.cancelCapture(state: state, message: NSLocalizedString(localString!, comment: ""))
        }
        else{
            self.setLookFromState(state: state)
        }
    }
    
    func isInRange(point: CGPoint) -> Bool {
        return (point.x >= -previewBoundsThreshold && point.x <= self.cameraPreviewView.frame.width + previewBoundsThreshold)
            && (point.y >= -previewBoundsThreshold && point.y <= self.cameraPreviewView.frame.height + previewBoundsThreshold)
    }
    
    func isOutsideView(points: Array<CGPoint>?) -> Bool {
        if(points != nil && points?.count == 4 && autoCapture){
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
            self.cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[0]),
            self.cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[1]),
            self.cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[2]),
            self.cameraPreviewView.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[3])
        ]
    }

    private func setPath(points: Array<CGPoint>) {
        let openSquarePath = UIBezierPath()

        openSquarePath.move(to: points[0])
        openSquarePath.addLine(to: points[1])
        openSquarePath.addLine(to: points[2])
        openSquarePath.addLine(to: points[3])
        openSquarePath.addLine(to: points[0])

        self.shapeLayer.path = openSquarePath.cgPath
        if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
            self.cornerLayer.setHorizontalCorners(point1: points[0], point2: points[1], point3: points[2], point4: points[3])
        } else {
            self.cornerLayer.setCorners(point1: points[0], point2: points[1], point3: points[2], point4: points[3])
        }
    }

    @objc func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.current.orientation
        guard self.lastDeviceOrientation != currentOrientation && self.messageLayer != nil else {
            return
        }

        if currentOrientation.isLandscape {
            if currentOrientation == UIDeviceOrientation.landscapeLeft {
                messageLayer.rotate(angle: -270)
            } else if currentOrientation == UIDeviceOrientation.landscapeRight {
                messageLayer.rotate(angle: 270)
            }
            self.lastDeviceOrientation = currentOrientation
        }
    }
    
    internal func addNavigationBackButton(){
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

    @objc internal func backTapped(_ sender: Any){
        self.cameraCaptureDelegate?.setCapturedImage(image: Image(), barcodeString: nil)
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - DocumentCaptureDelegate

extension DocumentCameraController: DocumentCaptureDelegate {

    public func readyToCapture() {
        DispatchQueue.main.async {
            if self.messageLayer != nil {
                if self.autoCapture {
                    self.setLookFromState(state: DocumentCameraController.CameraState.Capture)
                    self.setMessageCaptureSettings()
                    self.messageLayer.string = NSLocalizedString("1...", comment: "")
                } else {
                    self.setMessageDefaultSettings()
                    self.messageLayer.string = NSLocalizedString("acuant_camera_capturing", comment: "")
                }
                self.captured = true
            }
        }
    }

    public func documentCaptured(image: UIImage, barcodeString: String?) {
        let data = CameraMetaData().setCaptureType(captureType: autoCapture ? "AUTO" : "TAP")
        let result = ImagePreparation.createCameraImage(image: rotateImage(image: image),
                                                        data: data)
        self.navigationController?.popViewController(animated: true)
        self.cameraCaptureDelegate?.setCapturedImage(image: result, barcodeString: barcodeString)
    }

}

 //MARK: - FrameAnalysisDelegate

extension DocumentCameraController: FrameAnalysisDelegate {

    public func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?) {
        if self.cameraPreviewView == nil
            || self.messageLayer == nil
            || self.captured
            || !self.autoCapture
            || self.captureSession.isInterrupted {
            return
        }
        
        if isOutsideView(points: points) {
            self.currentState = FrameResult.DOCUMENT_NOT_IN_FRAME
        } else{
            self.currentState = frameResult
        }
        
        switch self.currentState {
            case FrameResult.NO_DOCUMENT:
                self.transitionState(state: CameraState.Align, localString: "acuant_camera_align")
            case FrameResult.SMALL_DOCUMENT:
                self.transitionState(state: CameraState.MoveCloser, localString: "acuant_camera_move_closer")
            case FrameResult.BAD_ASPECT_RATIO:
                self.transitionState(state: CameraState.MoveCloser, localString: "acuant_camera_move_closer")
            case FrameResult.DOCUMENT_NOT_IN_FRAME:
                self.transitionState(state: CameraState.MoveCloser, localString: "acuant_camera_outside_view")
            case FrameResult.GOOD_DOCUMENT:
                if let pts = points, pts.count == 4, autoCapture {
                    let scaledPoints = scalePoints(points: pts)
                    self.setPath(points: scaledPoints)
                    if !isHoldSteady {
                        self.transitionState(state: CameraState.Hold)

                        if self.isDocumentMoved(newPoints: scaledPoints) {
                            self.cancelCapture(state: CameraState.Steady, message: NSLocalizedString("acuant_camera_hold_steady", comment: ""))
                        } else if !self.captured {
                           self.triggerCapture()
                        }
                        self.currentPoints = scaledPoints
                    }
                }
        }
    }
}

// MARK: - AutoCaptureDelegate

extension DocumentCameraController: AutoCaptureDelegate {
    
    public func getAutoCapture() -> Bool {
        return autoCapture
    }
    
    public func setAutoCapture(autoCapture: Bool) {
        self.autoCapture = autoCapture
        if !autoCapture {
            DispatchQueue.main.async {
                self.messageLayer.string = NSLocalizedString("acuant_camera_manual_capture", comment: "")
            }
        }
    }
    
}

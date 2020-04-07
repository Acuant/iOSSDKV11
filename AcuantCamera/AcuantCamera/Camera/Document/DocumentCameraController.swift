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

@objcMembers public class DocumentCameraController : UIViewController, DocumentCaptureDelegate , FrameAnalysisDelegate {
    
    @objc public enum CameraState : Int {
        case Align = 0, MoveCloser = 1, Steady = 2, Hold = 3, Capture = 4
    }
    
    var captureWaitTime = 2
    var captureIntervalInSeconds = 0.9
    var captureSession: DocumentCaptureSession!
    var lastDeviceOrientation : UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var messageLayer :AcuantCameraTextView! = nil
    var cornerLayer : CameraCornerOverlayView! = nil
    var shapeLayer : CameraDocumentOverlayView! = nil
    var captured : Bool = false
    var hideNavBar : Bool = true
    var autoCapture = true
    var backButton : UIButton!
    
    private let context = CIContext()
    private var currentPoints : [CGPoint]? = nil
    private var options : AcuantCameraOptions? = nil
    weak private var cameraCaptureDelegate : CameraCaptureDelegate? = nil
    
    private var currentState = FrameResult.NO_DOCUMENT
    private var captureTimerState = 0.0
    private var isHoldSteady = false
    private var holdSteadyTimer: Timer!
    
    private let captureTime = 1
    private let documentMovementThreshold = 45
    
    private var currentStateCount = 0
    private var nextState = FrameResult.NO_DOCUMENT
    private var isNavigationHidden = false
    
    public class func getCameraController(delegate:CameraCaptureDelegate, cameraOptions: AcuantCameraOptions)->DocumentCameraController{
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
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.isNavigationHidden = self.navigationController?.isNavigationBarHidden ?? false
        self.navigationController?.setNavigationBarHidden(hideNavBar, animated: false)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotate(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        self.lastDeviceOrientation = UIDevice.current.orientation
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchAction(_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc internal func touchAction(_ sender:UITapGestureRecognizer){
        if(autoCapture == false){
            self.captureSession.enableCapture()
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCameraView()

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
    
    internal func startCameraView() {
        let captureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        self.captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self, frameDelegate: self,autoCapture:autoCapture, captureDevice: captureDevice)
        self.captureSession.start()
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer.frame = self.view.layer.bounds
        self.videoPreviewLayer.connection?.videoOrientation = .portrait
        
        if(self.messageLayer == nil) {
            self.messageLayer = AcuantCameraTextView(autoCapture: autoCapture)
        }
        self.messageLayer.setFrame(frame: self.view!.frame);
        if(self.cornerLayer == nil) {
            self.cornerLayer = CameraCornerOverlayView(options: options!)
        }
        self.cornerLayer.setFrame(frame: self.view!.frame)
        if(shapeLayer == nil) {
            shapeLayer = CameraDocumentOverlayView(options: options!)
        }
                
        self.videoPreviewLayer.addSublayer(self.shapeLayer)
        self.videoPreviewLayer.addSublayer(self.messageLayer)
        self.videoPreviewLayer.addSublayer(self.cornerLayer)
        self.view.layer.addSublayer(self.videoPreviewLayer)
        addNavigationBackButton()
    }
    
    public func documentCaptured(image: UIImage, barcodeString: String?) {
        let result = Image()
        result.image = rotateImage(image: image)
        self.navigationController?.popViewController(animated: true)
        self.cameraCaptureDelegate?.setCapturedImage(image: result, barcodeString: barcodeString)
    }
    
    public func rotateImage(image: UIImage) -> UIImage{
        if(self.lastDeviceOrientation == UIDeviceOrientation.landscapeRight){
            return image.rotate(radians: .pi/2)!
        }
        else{
            return image
        }
    }

    private func setLookFromState(state: DocumentCameraController.CameraState) {
        switch state {
        case DocumentCameraController.CameraState.MoveCloser:
            self.messageLayer.setDefaultSettings(frame: self.view.frame)
            self.cornerLayer.setColor(color: self.options?.colorBracketCloser)
            self.shapeLayer.hideBorder()
            break;
        case DocumentCameraController.CameraState.Hold:
            self.messageLayer.setCaptureSettings(frame: self.view.frame)
            self.cornerLayer.setColor(color: self.options?.colorBracketHold)
            self.shapeLayer.showBorder(color: self.options?.colorBracketHold)
            break;
        case DocumentCameraController.CameraState.Steady:
            self.messageLayer.setDefaultSettings(frame: self.view.frame)
            self.cornerLayer.setColor(color: self.options?.colorBracketHold)
            self.shapeLayer.showBorder(color: self.options?.colorBracketHold)
            break;
        case DocumentCameraController.CameraState.Capture:
            self.messageLayer.setCaptureSettings(frame: self.view.frame)
            self.cornerLayer.setColor(color: self.options?.colorBracketCapture)
            self.shapeLayer.showBorder(color: self.options?.colorBracketCapture)
            break;
        default://align
            self.messageLayer.setDefaultSettings(frame: self.view.frame)
            self.cornerLayer.setColor(color: self.options?.colorBracketAlign)
            self.cornerLayer.setDefaultCorners(frame: self.view.frame)
            self.shapeLayer.hideBorder()
            break;
        }
    }
    
    private func cancelCapture(state: CameraState, message: String){
        self.setLookFromState(state: state)
        self.messageLayer.string = message
        self.triggerHoldSteady()
        self.captureTimerState = 0.0
    }
    
    private func triggerHoldSteady(){
        if(!self.isHoldSteady){
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
    
    private func handleInterval(){
        if(captureTimerState == 0){
            self.messageLayer.string = NSLocalizedString("\(self.captureWaitTime)...", comment: "")
            self.captureTimerState = CFAbsoluteTimeGetCurrent()
        }
        else{
            let interval = getInterval(time: self.captureTimerState, duration: self.captureIntervalInSeconds)
            
            if(interval >= self.captureTime){
                self.captureSession.enableCapture()
            }
            else{
                self.messageLayer.string = NSLocalizedString("\(self.captureWaitTime - interval)...", comment: "")
            }
        }
    }
    
    private func triggerCapture(){
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
    
    
    private func transitionState(state: CameraState, localString: String? = nil){
        if(localString != nil){
            self.cancelCapture(state: state, message: NSLocalizedString(localString!, comment: ""))
        }
        else{
            self.setLookFromState(state: state)
        }
    }
    

    func isInRange(point: CGPoint) -> Bool{
        return (point.x >= 0 && point.x <= self.videoPreviewLayer.frame.width) && (point.y >= 0 && point.y <= self.videoPreviewLayer.frame.height)
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
    
    public func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?) {
        if(self.videoPreviewLayer == nil || self.messageLayer == nil || self.captured){
            return
        }
        
        if(isOutsideView(points: points)){
            self.currentState = FrameResult.DOCUMENT_NOT_IN_FRAME
        }
        else{
            self.currentState = frameResult
        }
        
        switch(self.currentState){
            case FrameResult.NO_DOCUMENT:
                self.transitionState(state: CameraState.Align, localString: "acuant_camera_align")
                break
            case FrameResult.SMALL_DOCUMENT:
                self.transitionState(state: CameraState.MoveCloser, localString: "acuant_camera_move_closer")
                break
            case FrameResult.BAD_ASPECT_RATIO:
                self.transitionState(state: CameraState.MoveCloser, localString: "acuant_camera_move_closer")
                break
            case FrameResult.DOCUMENT_NOT_IN_FRAME:
               self.transitionState(state: CameraState.Align, localString: "acuant_camera_outside_view")
               break
            case FrameResult.GOOD_DOCUMENT:
                if(points != nil && points?.count == 4 && autoCapture){
                    let scaledPoints = scalePoints(points: points!)
                    self.setPath(points: scaledPoints)
                    if(!isHoldSteady){
                        self.transitionState(state: CameraState.Hold)

                        if(self.isDocumentMoved(newPoints: scaledPoints)){
                            self.cancelCapture(state: CameraState.Steady, message: NSLocalizedString("acuant_camera_hold_steady", comment: ""))
                        }
                        else if(!self.captured){
                           self.triggerCapture()
                        }
                        self.currentPoints = scaledPoints
                    }
                }
                break
        }
    }
    private func scalePoints(points: Array<CGPoint>) -> Array<CGPoint>{
        return [
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[0]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[1]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[2]),
            self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points[3])
        ]
    }
    
    private func setPath(points: Array<CGPoint>){
        let openSquarePath = UIBezierPath()

        openSquarePath.move(to: points[0])
        openSquarePath.addLine(to: points[1])
        openSquarePath.addLine(to: points[2])
        openSquarePath.addLine(to: points[3])
        openSquarePath.addLine(to: points[0])
        
        self.shapeLayer.path = openSquarePath.cgPath
        self.cornerLayer.setCorners(point1: points[0], point2: points[1], point3: points[2], point4: points[3])
    }
    
    public func readyToCapture(){
        DispatchQueue.main.async {
            if(self.messageLayer != nil){
                if(self.autoCapture){
                    self.setLookFromState(state: DocumentCameraController.CameraState.Capture)
                    self.messageLayer.setCaptureSettings(frame: self.view.frame)
                    self.messageLayer.string = NSLocalizedString("1...", comment: "")
                }
                else{
                    self.messageLayer.setDefaultSettings(frame: self.view.frame)
                    self.messageLayer.string = NSLocalizedString("acuant_camera_capturing", comment: "")
                }
                self.captured = true
            }
        }
    }
    
    @objc internal func deviceDidRotate(notification:NSNotification)
    {
        let currentOrientation = UIDevice.current.orientation
        if(self.lastDeviceOrientation != currentOrientation && self.messageLayer != nil){
            if(currentOrientation.isLandscape){
                if(currentOrientation == UIDeviceOrientation.landscapeLeft){
                    rotateLayer(angle: -270, layer: messageLayer)
                }else if(currentOrientation == UIDeviceOrientation.landscapeRight){
                    rotateLayer(angle: 270, layer: messageLayer)
                }
                self.lastDeviceOrientation = currentOrientation;
            }
        }
    }
    
    
    internal func rotateLayer(angle: Double,layer:CALayer){
        layer.transform = CATransform3DMakeRotation(CGFloat(angle / 180.0 * .pi), 0.0, 0.0, 1.0)
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
        self.navigationController?.popViewController(animated: true)
    }
}


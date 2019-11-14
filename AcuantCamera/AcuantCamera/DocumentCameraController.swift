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
    weak var captureTimer: Timer?
    
    private let context = CIContext()
    private var isCapturing = false
    private var time = 2
    private var currentPoints : [CGPoint?] = [nil, nil, nil, nil]
    private var threshold = 25
    private var options : AcuantCameraOptions? = nil
    weak private var cameraCaptureDelegate : CameraCaptureDelegate? = nil
    
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
        startCameraView()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        self.view.backgroundColor = UIColor.white
        self.captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self, frameDelegate: self,autoCapture:autoCapture, captureDevice: captureDevice)
        
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoPreviewLayer.isHidden = true
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
        
        self.captureSession?.startRunning()

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 0.3
        }, completion: nil)
    }
    
    public func didStartCaptureSession() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1.0
        }, completion: nil)
        self.videoPreviewLayer.isHidden = false
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
    
    private func cancelCapture(state: CameraState, message: String){
        self.messageLayer.setLookFromState(state: state, frame: self.view.frame)
        self.messageLayer.string = message
        self.cornerLayer.setDefaultCorners(frame: self.view.frame)
        captureTimer?.invalidate()
        isCapturing = false
    }
    
    internal func capture(_ timer: Timer) {
        self.time -= 1
        if(time <= 1){
            self.captureSession.enableCapture()
            self.captureTimer?.invalidate()
        }
        else{
            self.messageLayer.string = NSLocalizedString("\(time)...", comment: "")
        }
    }
    
    private func triggerCapture(newPoints: Array<CGPoint>){
        DispatchQueue.main.async {
            if(!self.isCapturing){
                self.time = self.captureWaitTime
                self.isCapturing = true
                
                self.shapeLayer.showBorderFromState(state: CameraState.Hold)
                self.messageLayer.setLookFromState(state: CameraState.Hold, frame: self.view.frame)
                self.messageLayer.string = NSLocalizedString("\(self.time)...", comment: "")
                self.cornerLayer.setLookFromState(state: CameraState.Hold)
                self.currentPoints = newPoints
                
                self.captureTimer = Timer.scheduledTimer(
                    timeInterval: self.captureIntervalInSeconds,
                    target: self,
                    selector: #selector(self.capture(_:)),
                    userInfo: nil,
                    repeats: true)
            }
            else{
                if(self.isDocumentMoved(newPoints: newPoints)){
                    self.cancelCapture(state: CameraState.Steady, message: NSLocalizedString("acuant_camera_hold_steady", comment: ""))
                }
            }
        }
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
    
    public func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?) {
        if(self.videoPreviewLayer == nil || self.messageLayer == nil || self.captured){
            return
        }
        
        switch(frameResult){
            case FrameResult.NO_DOCUMENT:
                self.shapeLayer.showBorderFromState(state: CameraState.Align)
                self.cancelCapture(state: CameraState.Align, message: NSLocalizedString("acuant_camera_align", comment: ""))
                self.cornerLayer.setLookFromState(state: CameraState.Align)
                break;
            case FrameResult.SMALL_DOCUMENT:
                self.shapeLayer.showBorderFromState(state: CameraState.MoveCloser)
                self.cancelCapture(state: CameraState.MoveCloser, message: NSLocalizedString("acuant_camera_move_closer", comment: ""))
                self.cornerLayer.setLookFromState(state: CameraState.MoveCloser)
                break;
            case FrameResult.BAD_ASPECT_RATIO:
                self.shapeLayer.showBorderFromState(state: CameraState.Align)
                self.cancelCapture(state: CameraState.Align, message: NSLocalizedString("acuant_camera_align", comment: ""))
                self.cornerLayer.setLookFromState(state: CameraState.Align)
                break;
            case FrameResult.GOOD_DOCUMENT:
                if(points != nil && points?.count == 4 && autoCapture){
                    let openSquarePath = UIBezierPath()
                    let convertedPoints = [
                        self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![0]),
                        self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![1]),
                        self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![2]),
                        self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![3])
                    ]
                    
                    openSquarePath.move(to: convertedPoints[0])
                    openSquarePath.addLine(to: convertedPoints[1])
                    openSquarePath.addLine(to: convertedPoints[2])
                    openSquarePath.addLine(to: convertedPoints[3])
                    openSquarePath.addLine(to: convertedPoints[0])
                    
                    shapeLayer.path = openSquarePath.cgPath
                    self.cornerLayer.setCorners(point1: convertedPoints[0], point2: convertedPoints[1], point3: convertedPoints[2], point4: convertedPoints[3])
                
                    if(!self.captured){
                        self.triggerCapture(newPoints: convertedPoints)
                    }
                }
                break;
        }
    }
    
    public func readyToCapture(){
        DispatchQueue.main.async {
            if(self.messageLayer != nil){
                if(self.autoCapture){
                    self.messageLayer.setLookFromState(state: CameraState.Capture, frame: self.view.frame)
                    self.messageLayer.string = NSLocalizedString("1...", comment: "")
                }
                else{
                    self.messageLayer.setLookFromState(state: CameraState.Align, frame: self.view.frame)
                    self.messageLayer.string = NSLocalizedString("acuant_camera_capturing", comment: "")
                }
                self.shapeLayer.showBorderFromState(state: CameraState.Capture)
                self.cornerLayer.setLookFromState(state: CameraState.Capture)
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


//
//  FaceLivenessCameraController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public class AcuantFaceCaptureController : UIViewController {
    
    public var callback: ((UIImage?)->())?
    public var options: FaceAcuantCameraOptions?
    
    private var overlayView : UIView?
    private var captureSession: AcuantFaceCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var faceOval : CAShapeLayer?
    private var imageLayer: CALayer?
    private var messageLabel: CATextLayer!
    private var cornerlayer: FaceCameraCornerOverlayView!
    
    private var currentFrameTime = -1.0
    private var currentTimer: Double?
    private var backButton : UIButton!
    private var isNavigationHidden = false
    private let frameThrottleDuration = 0.2
    private var isCaptured = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isNavigationHidden = self.navigationController?.isNavigationBarHidden ?? false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.options = self.options ?? FaceAcuantCameraOptions()
        startCameraView()
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        self.navigationController?.setNavigationBarHidden(self.isNavigationHidden, animated: false)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        self.videoPreviewLayer.connection?.videoOrientation = orientation
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let connection =  self.videoPreviewLayer?.connection  {
            let previewLayerConnection : AVCaptureConnection = connection
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
        }
    }
    
    func startCameraView() {
        if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            
            captureSession = AcuantFaceCaptureSession(captureDevice: frontCameraDevice){[weak self]
                faceResult in
                
                if(self?.shouldSkipFrame(faceType: faceResult.state) ?? true){
                    return
                }
                
                DispatchQueue.main.async {
                    self?.handleOval(state: faceResult.state, faceRect: faceResult.faceRect, apeture: faceResult.cleanAperture);
                    switch(faceResult.state){
                    case AcuantFaceState.NONE:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_initial", color: self?.options?.fontColorDefault, fontSize: 25)
                        break
                    case AcuantFaceState.FACE_TOO_CLOSE:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_face_too_close", color: self?.options?.fontColorError, fontSize: 25)
                        break
                    case AcuantFaceState.FACE_TOO_FAR:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_face_too_far", color: self?.options?.fontColorError)
                        break
                    case AcuantFaceState.FACE_HAS_ANGLE:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_face_has_angle", color: self?.options?.fontColorError, fontSize: 25)
                        break;
                    case AcuantFaceState.FACE_NOT_IN_FRAME:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_face_not_in_frame", color: self?.options?.fontColorError)
                        break
                    case AcuantFaceState.FACE_MOVED:
                        self?.cancelCountdown()
                        self?.addMessage(messageKey: "acuant_face_camera_face_moved", color: self?.options?.fontColorError)
                        break
                    case AcuantFaceState.FACE_GOOD_DISTANCE:
                        if(faceResult.image != nil){
                            self?.handleCountdown(image: faceResult.image!)
                        }
                        break
                    }
                }
            }
            
            captureSession?.start()
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.frame = self.view.layer.bounds
            
            addoverlay()
            displayMessage()
            
            self.cornerlayer = FaceCameraCornerOverlayView()
            self.cornerlayer.setFrame(frame: self.view.frame)
            
            if(self.options!.showOval){
                faceOval = CAShapeLayer()
                faceOval?.fillColor = UIColor.clear.cgColor
                faceOval?.strokeColor = self.options!.bracketColorGood
                faceOval?.opacity = 0.5
                faceOval?.lineWidth = 5.0
                self.videoPreviewLayer.addSublayer(faceOval!)
            }
            
            self.videoPreviewLayer.addSublayer(self.cornerlayer)
            
            if let image = UIImage(named: self.options!.defaultImageUrl){
                UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                image.draw(at: .zero, blendMode: .normal, alpha: 0.6)
                if let newImage = UIGraphicsGetImageFromCurrentImageContext(){
                    self.imageLayer = CALayer()
                    
                    self.imageLayer!.frame = CGRect(x: (self.view.bounds.size.width/2) - (image.size.width/4), y:  (self.view.bounds.size.height/2) - (image.size.height/4), width: (image.size.width/2), height: (image.size.height/2))
                    self.imageLayer!.contents = newImage.cgImage
                    self.videoPreviewLayer.addSublayer(imageLayer!)
                }
                UIGraphicsEndImageContext()
            }
            
            self.view.layer.addSublayer(videoPreviewLayer)
            self.addNavigationBackButton()
        }
        else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func cancelCountdown(){
        currentTimer = nil
    }
    
    private func handleCountdown(image: UIImage){
        if(currentTimer == nil){
            currentTimer = CFAbsoluteTimeGetCurrent()
        }
        let time = self.options!.totalCaptureTime - Int(CFAbsoluteTimeGetCurrent() - (currentTimer ?? CFAbsoluteTimeGetCurrent()))
        
        if(time > 0){
            self.addMessage(messageKey: "acuant_face_camera_capturing_\(time)", color: self.options!.fontColorGood)
        }
        else{
            if(!self.isCaptured){
                self.isCaptured = true
                self.navigationController?.popViewController(animated: true)
                if let userCallback = self.callback {
                    userCallback(image)
                }
            }
        }
    }
    
    func handleImage(state: AcuantFaceState){
        if let defaultImg = imageLayer{
            if(state == .NONE){
                defaultImg.isHidden = false
            }
            else{
                defaultImg.isHidden = true
            }
        }
    }
    
    func handleOval(state: AcuantFaceState, faceRect: CGRect?, apeture: CGRect?){
        self.handleImage(state: state)
        self.setLookFromState(state: state)
        
        if(faceRect != nil && apeture != nil && state == AcuantFaceState.FACE_GOOD_DISTANCE){
            let scaled = CGRect(x: (faceRect!.origin.x - 150)/apeture!.width, y: 1-((faceRect!.origin.y)/apeture!.height + (faceRect!.height)/apeture!.height), width: (faceRect!.width + 150)/apeture!.width, height: (faceRect!.height)/apeture!.height)
            let faceRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: scaled)
            
            self.faceOval?.isHidden = false
            self.faceOval?.path = UIBezierPath.init(ovalIn: faceRect).cgPath
            
            self.cornerlayer.setCorners(point1: CGPoint(x: faceRect.origin.x, y: faceRect.origin.y), point2: CGPoint(x: faceRect.origin.x + faceRect.size.width, y: faceRect.origin.y), point3: CGPoint(x: faceRect.origin.x + faceRect.size.width, y: faceRect.origin.y + faceRect.size.height), point4: CGPoint(x: faceRect.origin.x, y: faceRect.origin.y + faceRect.size.height))
            
        }
        else{
            self.faceOval?.isHidden = true
            self.cornerlayer.setDefaultCorners(frame: self.view.frame)
        }
        
    }
    
    func shouldSkipFrame(faceType: AcuantFaceState) -> Bool{
        var skipFrame = false
        if(currentFrameTime < 0 || (faceType == AcuantFaceState.FACE_GOOD_DISTANCE) || CFAbsoluteTimeGetCurrent() - currentFrameTime >= self.frameThrottleDuration){
            currentFrameTime = CFAbsoluteTimeGetCurrent()
        }
        else{
            skipFrame = true
        }
        return skipFrame
    }
    
    func addoverlay(){
        overlayView =  UIView.init(frame: UIScreen.main.bounds)
        overlayView!.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        let height = overlayView!.bounds.height * 0.17
        let overlayPath = UIBezierPath.init(rect: CGRect(x: 0, y: 0, width: Int(overlayView!.bounds.width), height: Int(height)))
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath;
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd;
        fillLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        overlayView?.layer.addSublayer(fillLayer)
        videoPreviewLayer.addSublayer((overlayView?.layer)!)
    }
    
    func addMessage(messageKey: String, color: CGColor? = UIColor.red.cgColor, fontSize: CGFloat = 30){
        messageLabel.fontSize = fontSize
        messageLabel.foregroundColor = color
        messageLabel.string = NSLocalizedString(messageKey, comment: "")
        messageLabel.frame = getMessageRect()
    }
    
    func addNavigationBackButton(){
        let topPadding = getSafeArea()
        backButton = UIButton(frame: CGRect(x: self.view.frame.size.width-50,
                                            y: topPadding == 0 ? topPadding : topPadding-30, width: 50, height: 50))
        
        var attribs : [NSAttributedString.Key : Any?] = [:]
        attribs[NSAttributedString.Key.font]=UIFont.systemFont(ofSize: 20)
        attribs[NSAttributedString.Key.foregroundColor]=UIColor.gray
        attribs[NSAttributedString.Key.baselineOffset]=4
        
        let str = NSMutableAttributedString.init(string: "ⓧ", attributes: attribs as [NSAttributedString.Key : Any])
        backButton.setAttributedTitle(str, for: .normal)
        backButton.addTarget(self, action: #selector(backTapped(_:)), for: .touchUpInside)
        backButton.isOpaque=true
        backButton.imageView?.contentMode = .scaleAspectFit
        
        self.view.addSubview(backButton)
    }
    
    @objc internal func backTapped(_ sender: Any){
        if let userCallback = callback{
            userCallback(nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    public func setLookFromState(state: AcuantFaceState) {
        var color = UIColor.black.cgColor
        switch state {
        case .FACE_GOOD_DISTANCE:
            color = self.options!.bracketColorGood
            break;
        case .NONE:
            color = self.options!.bracketColorDefault
            break;
        default:
            color = self.options!.bracketColorError
            break;
        }
        self.cornerlayer.setColor(color: color)
    }
    
    func displayMessage(){
        messageLabel = CATextLayer()
        messageLabel.frame = getMessageRect()
        messageLabel.contentsScale = UIScreen.main.scale
        messageLabel.alignmentMode = CATextLayerAlignmentMode.center
        messageLabel.foregroundColor = UIColor.white.cgColor
        videoPreviewLayer.addSublayer(messageLabel)
    }
    
    func getSafeArea() -> CGFloat {
        if let window = UIApplication.shared.keyWindow{
            return window.safeAreaInsets.top
        }
        else{
            return 0
        }
    }
    
    func getMessageRect()->CGRect{
        let width = view.safeAreaLayoutGuide.layoutFrame.size.width
        let topPadding = getSafeArea()
        let height = overlayView!.bounds.height * 0.17
        
        let padding = topPadding == 0 ? (height - topPadding)/4 : topPadding
        return CGRect.init(x: 0, y: padding, width: width, height: height)
    }
}


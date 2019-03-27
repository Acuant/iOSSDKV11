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
public class DocumentCameraController : UIViewController, DocumentCaptureDelegate , FrameAnalysisDelegate{
    private let context = CIContext()
    private var cameraCaptureDelegate : CameraCaptureDelegate? = nil
    
    var captureWaitTime = 2
    
    let vcUtil = ViewControllerUtils()
    
    var captureSession: DocumentCaptureSession!
    var lastDeviceOrientation : UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let messageLayer = CATextLayer()
    
    var rightBorder : CALayer?
    var leftBorder : CALayer?
    var topBorder : CALayer?
    var bottomBorder : CALayer?
    
    var captured : Bool = false
    
    public class func getCameraController(delegate:CameraCaptureDelegate,captureWaitTime:Int)->DocumentCameraController{
        let c = DocumentCameraController()
        c.cameraCaptureDelegate = delegate
        c.captureWaitTime = captureWaitTime
        return c
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotate(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.lastDeviceOrientation = UIDevice.current.orientation
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCameraView()
        vcUtil.showActivityIndicator(uiView: self.view, text: "Camera..")
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
            captureSession.stopRunning()
        }
        self.videoPreviewLayer.removeFromSuperlayer()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        self.videoPreviewLayer.connection?.videoOrientation = orientation
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let connection =  self.videoPreviewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCameraView() {
        let captureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
            self.view.backgroundColor = UIColor.white
        self.captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self, frameDelegate: self, captureDevice: captureDevice)
            self.captureSession?.startRunning()
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.alpha = 0.3
            }, completion: nil)
    }
    
    public func didStartCaptureSession() {
        vcUtil.hideActivityIndicator(uiView: self.view)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1.0
        }, completion: nil)
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.videoPreviewLayer.frame = self.view.layer.bounds
        
        // Add Semi Transparent Border
        let color = UIColor.black.withAlphaComponent(0.6)
        let shortSide = self.view.layer.bounds.width*0.9
        let longSide = shortSide/0.65
        
        let lWidth = (self.view.layer.bounds.height - longSide)/2
        let sWidth = (self.view.layer.bounds.width - shortSide)/2
        
        self.addRightBorder(color: color, width: sWidth,space:lWidth)
        self.addLeftBorder(color: color, width: sWidth,space:lWidth)
        self.addTopBorder(color: color, width: lWidth)
        self.addBottomBorder(color: color, width: lWidth)
        
        // Add Center Message
        self.messageLayer.backgroundColor = UIColor.gray.cgColor
        self.messageLayer.fontSize = 30
        self.messageLayer.string = "ALLIGN"
        self.messageLayer.alignmentMode = CATextLayerAlignmentMode.center
        self.messageLayer.foregroundColor = UIColor.white.cgColor
        self.messageLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)));
        self.messageLayer.frame = CGRect(x: self.view.center.x-25, y: self.view.center.y-150, width: 50, height: 300)
        self.videoPreviewLayer.addSublayer(self.messageLayer)
        self.view.layer.addSublayer(self.videoPreviewLayer)
    }
    
    public func documentCaptured(image: UIImage, barcodeString: String?) {
        let result = Image()
        result.image = image
        self.navigationController?.popViewController(animated: true)
        self.cameraCaptureDelegate?.setCapturedImage(image: result, barcodeString: barcodeString)
    }
    
    public func onFrameAvailable(frameResult: FrameResult) {
        switch(frameResult){
            case FrameResult.NO_DOCUMENT:
                self.messageLayer.backgroundColor = UIColor.gray.cgColor
                animateMessage(message: "ALIGN")
                break;
            case FrameResult.SMALL_DOCUMENT:
                self.messageLayer.backgroundColor = UIColor.gray.cgColor
                animateMessage(message: "MOVE CLOSER")
                break;
            case FrameResult.BAD_ASPECT_RATIO:
                self.messageLayer.backgroundColor = UIColor.gray.cgColor
                animateMessage(message: "ALIGN")
                break;
            case FrameResult.GOOD_DOCUMENT:
                self.messageLayer.backgroundColor = UIColor.red.cgColor
                animateMessage(message: "HOLD STEADY")
                break;
            }
    }
    
    public func readyToCapture(){
        self.messageLayer.backgroundColor = UIColor.green.cgColor
        self.messageLayer.fontSize = 30
        self.messageLayer.string = "CAPTURING"
        captured = true
    }
    
    
    func animateMessage(message:String!){
        if(captured){
            return
        }
        self.messageLayer.string = message
        
        
    }

    func addRightBorder(color: UIColor, width: CGFloat,space:CGFloat) {
        rightBorder = CALayer()
        rightBorder?.borderColor = color.cgColor
        rightBorder?.borderWidth = width
        rightBorder?.frame = CGRect(x: self.view.frame.size.width-width, y: space, width: width, height: self.view.frame.size.height-2*space)
        videoPreviewLayer.addSublayer((rightBorder!))
    }
    func addLeftBorder(color: UIColor, width: CGFloat,space:CGFloat){
        leftBorder = CALayer()
        leftBorder?.borderColor = color.cgColor
        leftBorder?.borderWidth = width
        leftBorder?.frame = CGRect(x: 0, y: space, width: width, height: self.view.frame.size.height-2*space)
        videoPreviewLayer.addSublayer(leftBorder!)
    }
    func addTopBorder(color: UIColor, width: CGFloat){
        topBorder = CALayer()
        topBorder?.borderColor = color.cgColor
        topBorder?.borderWidth = width
        topBorder?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: width)
        videoPreviewLayer?.addSublayer(topBorder!)
    }
    func addBottomBorder(color: UIColor, width: CGFloat){
        bottomBorder = CALayer()
        bottomBorder?.borderColor = color.cgColor
        bottomBorder?.borderWidth = width
        bottomBorder?.frame = CGRect(x: 0, y: self.view.frame.size.height-width, width: self.view.frame.size.width, height: width)
        videoPreviewLayer.addSublayer(bottomBorder!)
    }
    
    @objc func deviceDidRotate(notification:NSNotification)
    {
        let currentOrientation = UIDevice.current.orientation
        if(self.lastDeviceOrientation != currentOrientation){
            if(currentOrientation.isLandscape){
                if(currentOrientation == UIDeviceOrientation.landscapeLeft){
                    rotateLayer(angle: -270, layer: messageLayer)
                }else if(currentOrientation == UIDeviceOrientation.landscapeRight){
                    rotateLayer(angle: 270, layer: messageLayer)
                }
            }
            self.lastDeviceOrientation = currentOrientation;
        }
    }
    
    
    func rotateLayer(angle: Double,layer:CALayer){
        layer.transform = CATransform3DMakeRotation(CGFloat(angle / 180.0 * .pi), 0.0, 0.0, 1.0)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.topBorder?.isHidden=true
            self.bottomBorder?.isHidden=true
            self.leftBorder?.isHidden=true
            self.rightBorder?.isHidden=true
            self.videoPreviewLayer.isHidden=true
            let orient = UIApplication.shared.statusBarOrientation
            
            switch orient {
                
            case .portrait:
                
                print("Portrait")
                
            case .landscapeLeft,.landscapeRight :
                
                print("Landscape")
                
            default:
                
                print("Anything But Portrait")
            }
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.videoPreviewLayer.isHidden=false
            self.captureSession.stopRunning()
            self.startCameraView()
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
}


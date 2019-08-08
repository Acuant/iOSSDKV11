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

@objcMembers public class DocumentCameraController : UIViewController, DocumentCaptureDelegate , FrameAnalysisDelegate{
    private let context = CIContext()
    weak private var cameraCaptureDelegate : CameraCaptureDelegate? = nil
    weak private var appDelegate : AppOrientationDelegate? = nil

    var captureWaitTime = 2
    
    //let vcUtil = ViewControllerUtils.createInstance()
    var captureSession: DocumentCaptureSession!
    var lastDeviceOrientation : UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let messageLayer = CATextLayer()

    let shapeLayer = CAShapeLayer()
    var rightBorder : CALayer?
    var leftBorder : CALayer?
    var topBorder : CALayer?
    var bottomBorder : CALayer?
    var captured : Bool = false
    var hideNavBar : Bool = true
    
    var autoCapture = true
        var backButton : UIButton!
    
    public class func getCameraController(delegate:CameraCaptureDelegate, captureWaitTime:Int,autoCapture:Bool,hideNavigationBar:Bool, appDelegate: AppOrientationDelegate)->DocumentCameraController{
        let c = DocumentCameraController()
        c.cameraCaptureDelegate = delegate
        c.captureWaitTime = captureWaitTime
        c.appDelegate = appDelegate
        c.autoCapture = autoCapture
        c.hideNavBar = hideNavigationBar
        return c
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.appDelegate?.onAppOrientationLockChanged(mode: UIInterfaceOrientationMask.portrait)
        self.navigationController?.setNavigationBarHidden(hideNavBar, animated: false)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotate(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.lastDeviceOrientation = UIDevice.current.orientation
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchAction(_:)))
        self.view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func touchAction(_ sender:UITapGestureRecognizer){
        if(autoCapture == false){
            self.captureSession.enableCapture()
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCameraView()
        //vcUtil.showActivityIndicator(uiView: self.view, text: NSLocalizedString("Camera", comment: ""))
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
        self.appDelegate?.onAppOrientationLockChanged(mode: UIInterfaceOrientationMask.all)
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
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCameraView() {
        let captureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
            self.view.backgroundColor = UIColor.white
        self.captureSession = DocumentCaptureSession.getDocumentCaptureSession(delegate: self, frameDelegate: self,autoCapture:autoCapture, captureDevice: captureDevice)
            self.captureSession?.startRunning()
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.alpha = 0.3
            }, completion: nil)
    }
    
    public func didStartCaptureSession() {
        //vcUtil.hideActivityIndicator(uiView: self.view)
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
        self.messageLayer.opacity = 0.6
        self.messageLayer.backgroundColor = UIColor.black.cgColor
        self.messageLayer.fontSize = 30
        if(autoCapture){
            self.messageLayer.string = NSLocalizedString("acuant_camera_align", value: "ALIGN" ,comment: "")
        }else{
            self.messageLayer.string = NSLocalizedString("acuant_camera_manual_capture", value: "ALIGN & TAP", comment: "")
        }
        self.messageLayer.alignmentMode = CATextLayerAlignmentMode.center
        self.messageLayer.foregroundColor = UIColor.white.cgColor
        self.messageLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)));
        self.messageLayer.frame = CGRect(x: self.view.center.x-25, y: self.view.center.y-150, width: 50, height: 300)
        self.videoPreviewLayer.addSublayer(self.messageLayer)
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = nil
        shapeLayer.path = UIBezierPath(rect: shapeLayer.bounds).cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor

        self.videoPreviewLayer.addSublayer(self.shapeLayer)
        
        self.view.layer.addSublayer(self.videoPreviewLayer)
        addNavigationBackButton()
    }
    
    public func documentCaptured(image: UIImage, barcodeString: String?) {
        let result = Image()
        result.image = image
        self.navigationController?.popViewController(animated: true)
        self.cameraCaptureDelegate?.setCapturedImage(image: result, barcodeString: barcodeString)
    }
    
    public func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?) {
        if(points != nil && points?.count == 4 && self.videoPreviewLayer != nil && autoCapture){
            let openSquarePath = UIBezierPath()
            
            let cornerPoint1 = self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![0])
            let cornerPoint2 = self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![1])
            let cornerPoint3 = self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![2])
            let cornerPoint4 = self.videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: points![3])
            
            openSquarePath.move(to: cornerPoint1)
            openSquarePath.addLine(to: cornerPoint2)
            openSquarePath.addLine(to: cornerPoint3)
            openSquarePath.addLine(to: cornerPoint4)
            openSquarePath.addLine(to: cornerPoint1)

            shapeLayer.path = openSquarePath.cgPath
        }
        else{
            shapeLayer.path = nil
        }
        
        switch(frameResult){
            case FrameResult.NO_DOCUMENT:
                shapeLayer.strokeColor = UIColor.red.cgColor
                self.messageLayer.backgroundColor = UIColor.black.cgColor
                animateMessage(message: NSLocalizedString("acuant_camera_align", value: "ALIGN", comment: ""))
                break;
            case FrameResult.SMALL_DOCUMENT:
                shapeLayer.strokeColor = UIColor.red.cgColor
                self.messageLayer.backgroundColor = UIColor.black.cgColor
                animateMessage(message: NSLocalizedString("acuant_camera_move_closer", value: "MOVE CLOSER", comment: ""))
                break;
            case FrameResult.BAD_ASPECT_RATIO:
                shapeLayer.strokeColor = UIColor.red.cgColor
                self.messageLayer.backgroundColor = UIColor.black.cgColor
                animateMessage(message: NSLocalizedString("acuant_camera_align", value: "ALIGN", comment: ""))
                break;
            case FrameResult.GOOD_DOCUMENT:
                shapeLayer.strokeColor = UIColor.red.cgColor
                self.messageLayer.backgroundColor = UIColor.red.cgColor
                animateMessage(message: NSLocalizedString("acuant_camera_hold_steady", value: "HOLD STEADY", comment: ""))
                break;
            }
    }
    
    public func readyToCapture(){
        shapeLayer.strokeColor = UIColor.green.cgColor
        self.messageLayer.backgroundColor = UIColor.green.cgColor
        self.messageLayer.fontSize = 30
        self.messageLayer.string = NSLocalizedString("acuant_camera_capturing", value: "CAPTURING", comment: "")
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
            self.videoPreviewLayer?.isHidden=true
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
            self.videoPreviewLayer?.isHidden=false
            self.captureSession?.stopRunning()
            self.startCameraView()
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    func addNavigationBackButton(){
        backButton = UIButton(frame: CGRect(x: 10, y: UIScreen.main.heightOfSafeArea()*0.065, width: 100, height: 21))
        
        let fullString = NSMutableAttributedString(string: "")
        // create our NSTextAttachment
        let image1Attachment = NSTextAttachment()
        
        // wrap the attachment in its own attributed string so we can append it
        let image1String = NSAttributedString(attachment: image1Attachment)
        
        // add the NSTextAttachment wrapper to our full string, then add some more text.
        fullString.append(image1String)
        
        var attribs : [NSAttributedString.Key : Any?] = [:]
        attribs[NSAttributedString.Key.font]=UIFont.systemFont(ofSize: 18)
        attribs[NSAttributedString.Key.foregroundColor]=UIColor.white
        attribs[NSAttributedString.Key.baselineOffset]=4
        let str = NSMutableAttributedString.init(string: "BACK", attributes: attribs as [NSAttributedString.Key : Any])
        fullString.append(str)
        
        backButton.setAttributedTitle(fullString, for: .normal)
        
        backButton.addTarget(self, action: #selector(backTapped(_:)), for: .touchUpInside)
        backButton.isOpaque=true
        backButton.imageView?.contentMode = .scaleAspectFit
        self.view.addSubview(backButton)
    }
    
    @objc func backTapped(_ sender: Any){
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
}


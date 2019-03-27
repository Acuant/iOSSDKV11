//
//  FaceLivelinessCameraController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantHGLiveliness

class FaceLivelinessCameraController : UIViewController,AcuantHGLiveFaceCaptureDelegate{
    
    public var delegate : AcuantHGLivelinessDelegate?
    
    private var overlayView : UIView?
    
    private var captured = false
    private let context = CIContext()
    var captureSession: FaceCaptureSession!
    var lastDeviceOrientation : UIDeviceOrientation!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var faceOval : CAShapeLayer?
    var messageBoundingRect : CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        captured = false
        super.viewDidAppear(animated)
        startCameraView()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        self.videoPreviewLayer.connection?.videoOrientation = orientation
    }
    
    override func viewDidLayoutSubviews() {
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
    
    func startCameraView() {
        var captureDevice: AVCaptureDevice?
        if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            captureDevice = frontCameraDevice
        }
        captureSession = AcuantHGLiveliness.getFaceCaptureSession(delegate: self,captureDevice: captureDevice,previewSize:self.view.layer.bounds.size)
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = self.view.layer.bounds
        addoverlay()
        displayBlinkMessage()
        
        self.view.layer.addSublayer(videoPreviewLayer)
        captureSession?.startRunning()
        
    }
    
    func liveFaceDetailsCaptured(liveFaceDetails: LiveFaceDetails?) {
        
        if(liveFaceDetails?.faceRect != nil && liveFaceDetails?.image != nil){
            
            let translatedFaceRect = self.calculateFaceRect(faceBounds: (liveFaceDetails?.faceRect)!, clearAperture:(liveFaceDetails?.cleanAperture)!)
            
            let topPadding = view.safeAreaInsets.top
            let bottomPadding = view.safeAreaInsets.bottom
            
            
            var width = (translatedFaceRect.width)
            width = 1.1*width
            
            var height = (translatedFaceRect.height)
            height = 1.3*height
            
            let x = (translatedFaceRect.origin.x) + ((translatedFaceRect.width)-width) + (topPadding + bottomPadding)/2
            let y = (translatedFaceRect.origin.y) + ((translatedFaceRect.height)-height)
            let faceRect =  CGRect.init(x: x, y: y, width: width, height:height)
            self.faceOval?.removeFromSuperlayer()
            faceOval = CAShapeLayer()
            faceOval?.path = UIBezierPath.init(ovalIn: faceRect).cgPath
            faceOval?.fillColor = UIColor.clear.cgColor
            faceOval?.strokeColor = UIColor.green.cgColor
            faceOval?.lineWidth = 5.0
            
            self.videoPreviewLayer.addSublayer((faceOval)!)
            if(liveFaceDetails?.isLiveFace)!{
                if(self.captured == false){
                    self.captured = true
                    self.navigationController?.popViewController(animated: true)
                    delegate?.liveFaceCaptured(image: (liveFaceDetails?.image)!)
                }
            }
        }else if(liveFaceDetails == nil || liveFaceDetails?.faceRect == nil){
            self.faceOval?.removeFromSuperlayer()
        }
        
    }
    
    // UI Functions
    
    func getViewFrame()->CGRect{
        return UIScreen.main.bounds
    }
    func getViewFrameSize()->CGSize{
        return getViewFrame().size
    }
    
    func getTransparentRect()->CGRect?{
        var retRect : CGRect? = nil
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            let overlayRect = getViewFrame()
            var hSpace = 0.75
            var vSpace = 0.75
            var rectWidth = overlayRect.size.width
            var rectHeight = overlayRect.size.height
            if(UIDevice.current.orientation.isLandscape){
                let tmp = rectWidth
                rectWidth = rectHeight
                rectHeight = tmp
                
                hSpace = 0.75
                vSpace = 0.5
            }
            let width = rectWidth*CGFloat(hSpace)
            let height = rectHeight*CGFloat(vSpace)
            let horizontalSpace = (overlayRect.size.width-width)/2
            let verticalSpace = CGFloat(0.15)*overlayRect.size.height;
            retRect = CGRect.init(x:horizontalSpace, y:verticalSpace, width: width, height: height)
        }else{
            let overlayRect = getViewFrame()
            var hSpace = 0.95
            var vSpace = 0.75
            var rectWidth = overlayRect.size.width
            var rectHeight = overlayRect.size.height
            if(UIDevice.current.orientation.isLandscape){
                let tmp = rectWidth
                rectWidth = rectHeight
                rectHeight = tmp
                
                hSpace = 0.75
                vSpace = 0.45
            }
            let width = rectWidth*CGFloat(hSpace)
            let height = rectHeight*CGFloat(vSpace)
            let horizontalSpace = (overlayRect.size.width-width)/2
            let verticalSpace = CGFloat(0.15)*overlayRect.size.height;
            retRect = CGRect.init(x:horizontalSpace, y:verticalSpace, width: width, height: height)
        }
        return retRect
    }
    func getTransparentBezierPath()->UIBezierPath?{
        let path = getTransparentRect()
        if(path != nil){
            let transparentPath = UIBezierPath.init(ovalIn: getTransparentRect()!)
            return transparentPath
        }
        return nil
    }
    
    func addoverlay(){
        overlayView =  UIView.init(frame: getViewFrame())
        overlayView?.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        let overlayPath = UIBezierPath.init(rect: (overlayView?.bounds)!)
        let transparentPath = getTransparentBezierPath()
        overlayPath.append(transparentPath!)
        overlayPath.usesEvenOddFillRule=true
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath;
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd;
        fillLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        overlayView?.layer.addSublayer(fillLayer)
        videoPreviewLayer.addSublayer((overlayView?.layer)!)
    }
    
    func displayBlinkMessage(){
        let message = NSMutableAttributedString.init(string: "Blink when green oval appears")
        message.addAttribute(kCTForegroundColorAttributeName as NSAttributedString.Key,value: UIColor.white, range: NSRange.init(location: 0, length: message.length))
        message.addAttribute(kCTForegroundColorAttributeName as NSAttributedString.Key,value: UIColor.green, range: NSRange.init(location: 11, length: 10))
        message.addAttribute(kCTFontAttributeName as NSAttributedString.Key,value:UIFont.boldSystemFont(ofSize: 13), range: NSRange.init(location: 0, length: message.length))
        
        
        let blinkLabel = CATextLayer()
        blinkLabel.frame = getBlinkMessageRect()
        blinkLabel.string = message
        blinkLabel.fontSize = 15
        blinkLabel.contentsScale = UIScreen.main.scale
        blinkLabel.alignmentMode = CATextLayerAlignmentMode.center
        blinkLabel.foregroundColor = UIColor.white.cgColor
        videoPreviewLayer.addSublayer(blinkLabel)
    }
    
    func getBlinkMessageRect()->CGRect{
        let width : CGFloat = 220
        let height : CGFloat  = 30
        let mainViewFrame = getViewFrame()
        return CGRect.init(x: mainViewFrame.origin.x + mainViewFrame.size.width/2-width/2, y: 0.08*mainViewFrame.size.height, width: width, height: height)
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
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
            self.captureSession.stopRunning()
            var captureDevice: AVCaptureDevice?
            if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                captureDevice = frontCameraDevice
            }
            self.captureSession = AcuantHGLiveliness.getFaceCaptureSession(delegate: self,captureDevice: captureDevice,previewSize:self.view.layer.bounds.size)
            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.videoPreviewLayer.frame = self.view.layer.bounds
            self.addoverlay()
            self.displayBlinkMessage()
            
            self.view.layer.addSublayer(self.videoPreviewLayer)
            self.captureSession?.startRunning()
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    // Face rect adjustment
    
    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        //let apertureRatio = apertureSize.height / apertureSize.width
        //let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSize.zero
        
        size.width = apertureSize.height * (frameSize.height / apertureSize.width)
        size.height = frameSize.height
        
        var videoBox = CGRect(origin: .zero, size: size)
        
        if (size.width < frameSize.width) {
            videoBox.origin.x = (frameSize.width - size.width) / 2.0
        } else {
            videoBox.origin.x = (size.width - frameSize.width) / 2.0
        }
        
        if (size.height < frameSize.height) {
            videoBox.origin.y = (frameSize.height - size.height) / 2.0
        } else {
            videoBox.origin.y = (size.height - frameSize.height) / 2.0
        }
        
        return videoBox
    }
    
    func calculateFaceRect(faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
        var parentFrameSize = self.videoPreviewLayer.frame.size
        var apperatureSize = clearAperture.size
        if #available(iOS 11.0, *) {
            parentFrameSize.width = parentFrameSize.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
            
            apperatureSize.width = apperatureSize.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 11.0, *) {
            parentFrameSize.height = parentFrameSize.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom
            
            apperatureSize.height = apperatureSize.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom
        } else {
            // Fallback on earlier versions
        }
        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: apperatureSize)
        
        var faceRect = faceBounds
        
        swap(&faceRect.size.width, &faceRect.size.height)
        swap(&faceRect.origin.x, &faceRect.origin.y)
        
        let widthScaleBy = previewBox.size.width / apperatureSize.height
        let heightScaleBy = previewBox.size.height / apperatureSize.width
        faceRect.size.width *= widthScaleBy
        faceRect.size.height *= heightScaleBy
        faceRect.origin.x *= widthScaleBy
        faceRect.origin.y *= heightScaleBy
        
        
        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
        let frame = CGRect(x: (parentFrameSize.width) - faceRect.origin.x - faceRect.size.width - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
        
        return frame
    }
    
}



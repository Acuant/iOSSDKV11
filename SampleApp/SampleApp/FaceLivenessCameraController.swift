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
import AcuantHGLiveness

class FaceLivenessCameraController : UIViewController, AcuantHGLiveFaceCaptureDelegate{
    
    weak public var delegate : AcuantHGLivenessDelegate?
    private var overlayView : UIView?
    private var captured = false
    private var captureSession: FaceCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var faceOval : CAShapeLayer?
    private var blinkLabel: CATextLayer!
    private var currentFrameTime = -1.0
    public var frameRefreshSpeed = 10
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCameraView()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captured = false
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
            let previewLayerConnection : AVCaptureConnection = connection
            updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
        }
    }
    
    func startCameraView() {
        var captureDevice: AVCaptureDevice?
        if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            captureDevice = frontCameraDevice
        }
        captureSession = AcuantHGLiveness.getFaceCaptureSession(delegate: self,captureDevice: captureDevice)
        captureSession?.start()
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = self.view.layer.bounds
        
        addoverlay()
        displayBlinkMessage()
        
        faceOval = CAShapeLayer()
        faceOval?.fillColor = UIColor.clear.cgColor
        faceOval?.strokeColor = UIColor.green.cgColor
        faceOval?.lineWidth = 5.0
        self.videoPreviewLayer.addSublayer(faceOval!)
        self.view.layer.addSublayer(videoPreviewLayer)
        
    }
    
    func shouldSkipFrame(liveFaceDetails: LiveFaceDetails?,faceType: AcuantFaceType) -> Bool{
        var skipFrame = false
        if(currentFrameTime < 0 || (liveFaceDetails != nil && liveFaceDetails!.isLiveFace) || CFAbsoluteTimeGetCurrent() - currentFrameTime >= 1/Double(frameRefreshSpeed)){
            currentFrameTime = CFAbsoluteTimeGetCurrent()
        }
        else{
            skipFrame = true
        }
        return skipFrame
    }
    
    func liveFaceDetailsCaptured(liveFaceDetails: LiveFaceDetails?, faceType: AcuantFaceType) {
        if(shouldSkipFrame(liveFaceDetails:liveFaceDetails, faceType: faceType)){
            return
        }
        
        switch(faceType){
            case AcuantFaceType.NONE:
                self.addMessage()
                break
            case .FACE_TOO_CLOSE:
                self.addMessage(message: NSLocalizedString("hg_too_close", comment: ""))
                break
            case .FACE_TOO_FAR:
                self.addMessage(message: NSLocalizedString("hg_too_far_away", comment: ""))
                break
            case .FACE_NOT_IN_FRAME:
                self.addMessage(message: NSLocalizedString("hg_move_in_frame", comment: ""))
                break
            case .FACE_GOOD_DISTANCE:
                self.addMessage(message: NSLocalizedString("hg_blink", comment: ""), color: UIColor.green.cgColor)
                break
            case .FACE_MOVED:
                self.addMessage(message: NSLocalizedString("hg_hold_steady", comment: ""))
                break
        }
        
        if(liveFaceDetails?.faceRect != nil && liveFaceDetails?.cleanAperture != nil){
            let rect = liveFaceDetails!.faceRect!.toCGRect()
            let totalSize = liveFaceDetails!.cleanAperture!.toCGRect()
            let scaled = CGRect(x: (rect.origin.x - 150)/totalSize.width, y: 1-((rect.origin.y)/totalSize.height + (rect.height)/totalSize.height), width: (rect.width + 150)/totalSize.width, height: (rect.height)/totalSize.height)
            let faceRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: scaled)
            
            self.faceOval?.isHidden = false
            faceOval?.path = UIBezierPath.init(ovalIn: faceRect).cgPath
            
            if(liveFaceDetails?.isLiveFace != nil && liveFaceDetails!.isLiveFace){
                if(self.captured == false){
                    self.captured = true
                    self.navigationController?.popViewController(animated: true)
                    delegate?.liveFaceCaptured(image: (liveFaceDetails?.image)!)
                }
            }
        }
        else if(liveFaceDetails == nil || liveFaceDetails?.faceRect == nil){
            self.faceOval?.isHidden = true
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
            let hSpace = 0.75
            let vSpace = 0.75
            let rectWidth = overlayRect.size.width
            let rectHeight = overlayRect.size.height
            
            let width = rectWidth*CGFloat(hSpace)
            let height = rectHeight*CGFloat(vSpace)
            let horizontalSpace = (overlayRect.size.width-width)/2
            let verticalSpace = CGFloat(0.15)*overlayRect.size.height;
            retRect = CGRect.init(x:horizontalSpace, y:verticalSpace, width: width, height: height)
        }else{
            let overlayRect = getViewFrame()
            let hSpace = 0.95
            let vSpace = 0.75
            let rectWidth = overlayRect.size.width
            let rectHeight = overlayRect.size.height
            
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
    
    func addMessage(message: String? = nil, color: CGColor = UIColor.red.cgColor, fontSize: CGFloat = 25){
        if(message == nil){
            let msg = NSMutableAttributedString.init(string: NSLocalizedString("hg_align_face_and_blink", comment: ""))
            msg.addAttribute(kCTFontAttributeName as NSAttributedString.Key,value:UIFont.systemFont(ofSize: 25), range: NSRange.init(location: 0, length: msg.length))
            msg.addAttribute(kCTForegroundColorAttributeName as NSAttributedString.Key,value: UIColor.white, range: NSRange.init(location: 0, length: msg.length))
            
            blinkLabel.fontSize = 15
            blinkLabel.foregroundColor = UIColor.white.cgColor
            blinkLabel.string = msg
        }
        else{
            blinkLabel.fontSize = fontSize
            blinkLabel.foregroundColor = color
            blinkLabel.string = message
        }
    }
    func displayBlinkMessage(){
        blinkLabel = CATextLayer()
        blinkLabel.frame = getBlinkMessageRect()
        blinkLabel.contentsScale = UIScreen.main.scale
        blinkLabel.alignmentMode = CATextLayerAlignmentMode.center
        blinkLabel.foregroundColor = UIColor.white.cgColor
        addMessage()
        videoPreviewLayer.addSublayer(blinkLabel)
    }
    
    func getBlinkMessageRect()->CGRect{
        let width : CGFloat = 330
        let height : CGFloat  = 55
        let mainViewFrame = getViewFrame()
        return CGRect.init(x: mainViewFrame.origin.x + mainViewFrame.size.width/2-width/2, y: 0.06*mainViewFrame.size.height, width: width, height: height)
        
    }
}



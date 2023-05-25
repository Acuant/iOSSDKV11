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
import AcuantImagePreparation

class FaceLivenessCameraController: UIViewController, AcuantHGLiveFaceCaptureDelegate {
    
    weak public var delegate: HGLivenessDelegate?
    private var captureSession: FaceCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var overlayLayer: CAShapeLayer?
    private var faceOval: CAShapeLayer?
    private var blinkLabel: CATextLayer!
    private var alertView: AlertView?
    private var currentFrameTime = -1.0
    public var frameRefreshSpeed = 10

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? BaseNavigationController)?.supportedInterfaceOrientations = .portrait
        addCaptureSessionObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCameraView()
        handleRotateToPortraitAlertIfPhone()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        captureSession.stop()
        NotificationCenter.default.removeObserver(self)
        (navigationController as? BaseNavigationController)?.resetToSupportedOrientations()
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        alertView?.frame = view.frame
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self = self else { return }

            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation)
            self.handleRotateToPortraitAlertIfPhone()
        })
    }

    private func addCaptureSessionObservers() {
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self, self.alertView == nil else { return }

            let alertView = AlertView(frame: self.view.bounds, text: NSLocalizedString("acuant_face_camera_paused", comment: ""))
            self.view.addSubview(alertView)
            self.alertView = alertView
        }

        NotificationCenter.default.addObserver(forName: .AVCaptureSessionInterruptionEnded,
                                               object: captureSession,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }

            self.alertView?.removeFromSuperview()
            self.alertView = nil
        }
    }

    private func handleRotateToPortraitAlertIfPhone() {
        guard
            UIDevice.current.userInterfaceIdiom == .phone,
            let interfaceOrientation = self.view.window?.interfaceOrientation
        else {
            return
        }

        if interfaceOrientation.isLandscape {
            self.alertView = AlertView(frame: self.view.frame,
                                       text: NSLocalizedString("acuant_face_camera_rotate_portrait", comment: ""))
            self.view.addSubview(self.alertView!)
            self.captureSession.stop()
        } else if !captureSession.isRunning {
            self.alertView?.removeFromSuperview()
            self.captureSession.resume()
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
        overlayLayer?.path = createOvalPath().cgPath
        blinkLabel.frame = getBlinkMessageRect()
        videoPreviewLayer.removeAllAnimations()
    }
    
    func startCameraView() {
        var captureDevice: AVCaptureDevice?
        if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            captureDevice = frontCameraDevice
        }
        captureSession = HGLiveness.getFaceCaptureSession(delegate: self, captureDevice: captureDevice)
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.bounds
        
        overlayLayer = createOverlay()
        videoPreviewLayer.addSublayer(overlayLayer!)
        displayBlinkMessage()
        
        faceOval = CAShapeLayer()
        faceOval?.fillColor = UIColor.clear.cgColor
        faceOval?.strokeColor = UIColor.green.cgColor
        faceOval?.lineWidth = 5.0
        videoPreviewLayer.addSublayer(faceOval!)
        view.layer.addSublayer(videoPreviewLayer)
        
        captureSession?.start {
            self.rotateCameraPreview(to: self.view.window?.interfaceOrientation)
        }
    }
    
    func shouldSkipFrame(liveFaceDetails: LiveFaceDetails?, faceType: AcuantFaceType) -> Bool {
        var skipFrame = false
        if currentFrameTime < 0
            || (liveFaceDetails != nil && liveFaceDetails!.isLiveFace)
            || CFAbsoluteTimeGetCurrent() - currentFrameTime >= 1/Double(frameRefreshSpeed) {
            currentFrameTime = CFAbsoluteTimeGetCurrent()
        } else {
            skipFrame = true
        }
        return skipFrame
    }
    
    private func getTargetWidth(width: Int, height: Int) -> Int {
        if width > height {
            return Int(720 * (Float(width)/Float(height)))
        } else{
            return 720
        }
    }
    
    func liveFaceDetailsCaptured(liveFaceDetails: LiveFaceDetails?, faceType: AcuantFaceType) {
        if shouldSkipFrame(liveFaceDetails: liveFaceDetails, faceType: faceType) {
            return
        }
        
        switch faceType {
        case AcuantFaceType.NONE:
            addMessage()
        case .FACE_TOO_CLOSE:
            addMessage(message: NSLocalizedString("hg_too_close", comment: ""))
        case .FACE_TOO_FAR:
            addMessage(message: NSLocalizedString("hg_too_far_away", comment: ""))
        case .FACE_NOT_IN_FRAME:
            addMessage(message: NSLocalizedString("hg_move_in_frame", comment: ""))
        case .FACE_HAS_ANGLE:
            addMessage(message: NSLocalizedString("hg_has_angle", comment: ""))
        case .FACE_MOVED:
            addMessage(message: NSLocalizedString("hg_hold_steady", comment: ""))
        case .FACE_GOOD_DISTANCE:
            addMessage(message: NSLocalizedString("hg_blink", comment: ""), color: UIColor.green.cgColor)
        @unknown default:
            break
        }
        
        toggleFaceOval(liveFaceDetails: liveFaceDetails)
        if let faceDetails = liveFaceDetails, faceDetails.isLiveFace,
           let image = faceDetails.image,
           let resizedImage = ImagePreparation.resize(image: image,
                                                   targetWidth: getTargetWidth(width: Int(image.size.width), height: Int(image.size.height))),
           let signedImageData = ImagePreparation.sign(image: resizedImage) {
            navigationController?.popViewController(animated: true)
            delegate?.liveFaceCaptured(result: HGLivenessResult(image: resizedImage, jpegData: signedImageData))
        } else {
            delegate?.liveFaceCaptured(result: nil)
        }
    }

    private func toggleFaceOval(liveFaceDetails: LiveFaceDetails?) {
        if let faceRect = liveFaceDetails?.faceRect,
           let cleanAperture = liveFaceDetails?.cleanAperture {
            let rect = faceRect.toCGRect()
            let totalSize = cleanAperture.toCGRect()
            var x = (rect.origin.x - 150) / totalSize.width
            var width = (rect.width + 150) / totalSize.width
            var height = rect.height / totalSize.height
            if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
                x = rect.origin.x / totalSize.width
                width = rect.width / totalSize.width
                height = (rect.height + 150) / totalSize.height
            }
            let scaled = CGRect(x: x,
                                y: 1 - ((rect.origin.y) / totalSize.height + (rect.height) / totalSize.height),
                                width: width,
                                height: height)

            let faceRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: scaled)
            faceOval?.isHidden = false
            faceOval?.path = UIBezierPath(ovalIn: faceRect).cgPath
        } else if liveFaceDetails == nil || liveFaceDetails?.faceRect == nil {
            faceOval?.isHidden = true
        }
    }

    private func createRectangleContainer(hSpace: Double, vSpace: Double) -> CGRect {
        let overlayRect = view.bounds
        let rectWidth = overlayRect.size.width
        let rectHeight = overlayRect.size.height

        let width = rectWidth * CGFloat(hSpace)
        let height = rectHeight * CGFloat(vSpace)
        let horizontalSpace = (overlayRect.size.width - width) / 2
        let verticalSpace = CGFloat(0.15) * overlayRect.size.height

        return CGRect(x: horizontalSpace, y: verticalSpace, width: width, height: height)
    }
    
    private func createTransparentOval() -> UIBezierPath {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
                return UIBezierPath(ovalIn: createRectangleContainer(hSpace: 0.4, vSpace: 0.8))
            }
            return UIBezierPath(ovalIn: createRectangleContainer(hSpace: 0.75, vSpace: 0.75))
        }
        if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
            return UIBezierPath(ovalIn: createRectangleContainer(hSpace: 0.3, vSpace: 0.8))
        }
        return UIBezierPath(ovalIn: createRectangleContainer(hSpace: 0.95, vSpace: 0.75))
    }
    
    private func createOverlay() -> CAShapeLayer {
        let overlayPath = createOvalPath()
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        return fillLayer
    }
    
    private func createOvalPath() -> UIBezierPath {
        let overlayPath = UIBezierPath(rect: view.bounds)
        let transparenOval = createTransparentOval()
        overlayPath.append(transparenOval)
        overlayPath.usesEvenOddFillRule = true
        return overlayPath
    }

    private func addMessage(message: String? = nil, color: CGColor = UIColor.red.cgColor, fontSize: CGFloat = 25) {
        if message == nil {
            let msg = NSMutableAttributedString.init(string: NSLocalizedString("hg_align_face_and_blink", comment: ""))
            msg.addAttribute(kCTFontAttributeName as NSAttributedString.Key,
                             value: UIFont.systemFont(ofSize: 25),
                             range: NSRange(location: 0, length: msg.length))
            msg.addAttribute(kCTForegroundColorAttributeName as NSAttributedString.Key,
                             value: UIColor.white,
                             range:NSRange(location: 0, length: msg.length))
            blinkLabel.fontSize = 15
            blinkLabel.foregroundColor = UIColor.white.cgColor
            blinkLabel.string = msg
        } else {
            blinkLabel.fontSize = fontSize
            blinkLabel.foregroundColor = color
            blinkLabel.string = message
        }
    }

    private func displayBlinkMessage() {
        blinkLabel = CATextLayer()
        blinkLabel.frame = getBlinkMessageRect()
        blinkLabel.contentsScale = UIScreen.main.scale
        blinkLabel.alignmentMode = CATextLayerAlignmentMode.center
        blinkLabel.foregroundColor = UIColor.white.cgColor
        addMessage()
        videoPreviewLayer.addSublayer(blinkLabel)
    }
    
    private func getBlinkMessageRect() -> CGRect {
        let width: CGFloat = 330
        let height: CGFloat = 55
        let mainViewFrame = view.bounds
        return CGRect(x: mainViewFrame.origin.x + mainViewFrame.size.width / 2 - width / 2,
                      y: 0.06 * mainViewFrame.size.height,
                      width: width,
                      height: height)
    }
}

//MARK: - Orientation extensions

extension UIWindow {

    var interfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 13, *) {
            return windowScene?.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

}

extension UIInterfaceOrientation {

    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }

}

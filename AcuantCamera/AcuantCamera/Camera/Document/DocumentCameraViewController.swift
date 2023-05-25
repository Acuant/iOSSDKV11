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

@objcMembers public class DocumentCameraViewController: CameraViewController {
    private var currentPoints: [CGPoint]?
    private var captureTimerState = 0.0
    private var isHoldSteady = false
    private var holdSteadyTimer: Timer!
    private var captured = false
    private var autoCapture = true
    private let captureTime = 1
    private let documentMovementThreshold = 25
    private var currentStateCount = 0
    private let docOptions: DocumentCameraOptions
    
    public weak var delegate: DocumentCameraViewControllerDelegate?

    public init(options: DocumentCameraOptions) {
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        let captureSession = DocumentCaptureSession(captureDevice: captureDevice)
        docOptions = options
        autoCapture = docOptions.autoCapture
        super.init(options: options, captureSession: captureSession)
        captureSession.frameDelegate = self
        captureSession.autoCaptureDelegate = self
        captureSession.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addTapGesture()
        if !autoCapture {
            messageLayer.string = docOptions.textForManualCapture
        }
    }

    override func onCameraInterrupted() {
        messageLayer.string = options.textForCameraPaused
    }

    override func onBackTapped() {
        delegate?.onCaptured(image: Image(), barcodeString: nil)
    }

    override func onPreviewCreated() {
        cameraPreviewView.videoPreviewLayer.videoGravity = UIDevice.current.userInterfaceIdiom == .pad
            ? .resizeAspectFill
            : .resizeAspect
    }

    private func addTapGesture() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchAction(_:)))
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc func touchAction(_ sender: UITapGestureRecognizer) {
        if !autoCapture, !captureSession.isInterrupted {
            captureSession.enableCapture()
        }
    }

    private func setLookFromState(state: DocumentCameraState) {
        let color = docOptions.colorForState(state)
        switch state {
        case .align:
            setMessageDefaultSettings()
            setCornerSettings(color: color)
            detectionBoxLayer.hideBorder()
        case .moveCloser, .tooClose:
            setMessageDefaultSettings()
            setCornerSettings(color: color)
            detectionBoxLayer.hideBorder()
        case .hold:
            setMessageCaptureSettings()
            cornerLayer.setColor(color: color)
            detectionBoxLayer.showBorder(color: color)
        case .steady:
            setMessageDefaultSettings()
            cornerLayer.setColor(color: color)
            detectionBoxLayer.showBorder(color: color)
        case .capture:
            setMessageCaptureSettings()
            cornerLayer.setColor(color: color)
            detectionBoxLayer.showBorder(color: color)
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
            landscapeSetting(view.frame)
        } else {
            portraitSetting(view.frame)
        }
    }

    private func transitionTo(state: DocumentCameraState, message: String) {
        setLookFromState(state: state)
        messageLayer.string = message
        triggerHoldSteady()
        captureTimerState = 0
    }
    
    private func triggerHoldSteady() {
        if !isHoldSteady, autoCapture {
            isHoldSteady = true
            holdSteadyTimer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(delayTimer(_:)),
                userInfo: nil,
                repeats: false)
        }
    }

    @objc private func delayTimer(_ timer: Timer) {
        isHoldSteady = false
        holdSteadyTimer.invalidate()
    }
    
    private func triggerCapture() {
        if captureTimerState == 0 {
            messageLayer.string = "\(docOptions.countdownDigits)..."
            captureTimerState = CFAbsoluteTimeGetCurrent()
        } else {
            let interval = getInterval(time: captureTimerState,
                                       duration: Double(docOptions.timeInMillisecondsPerCountdownDigit) / Double(1000))
            if interval >= docOptions.countdownDigits {
                if captureSession.captureDevice.isAdjustingFocus {
                    transitionTo(state: .steady, message: docOptions.textForState(.steady))
                } else {
                    captureSession.enableCapture()
                }
            } else {
                messageLayer.string = "\(docOptions.countdownDigits - interval)..."
            }
        }
    }
    
    private func getInterval(time: Double, duration: Double) -> Int {
        let current = CFAbsoluteTimeGetCurrent() - time
        return Int(current/duration)
    }
    
    public func isDocumentMoved(points: [CGPoint]) -> Bool {
        guard let currentPoints = self.currentPoints, points.count == currentPoints.count else {
            return false
        }

        for i in 0..<currentPoints.count {
            if Int(abs(currentPoints[i].x - points[i].x)) > documentMovementThreshold
                || Int(abs(currentPoints[i].y - points[i].y)) > documentMovementThreshold {
                return true
            }
        }

        return false
    }

    private func setPath(points: [CGPoint]) {
        let openSquarePath = UIBezierPath()

        openSquarePath.move(to: points[0])
        openSquarePath.addLine(to: points[1])
        openSquarePath.addLine(to: points[2])
        openSquarePath.addLine(to: points[3])
        openSquarePath.addLine(to: points[0])

        detectionBoxLayer.path = openSquarePath.cgPath
        if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
            cornerLayer.setHorizontalCorners(point1: points[0], point2: points[1], point3: points[2], point4: points[3])
        } else {
            cornerLayer.setCorners(point1: points[0], point2: points[1], point3: points[2], point4: points[3])
        }
    }

    private func rotateImage(image: UIImage) -> UIImage {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight {
            return image.rotate(radians: .pi/2)!
        }
        return image
    }

}

// MARK: - DocumentCaptureDelegate

extension DocumentCameraViewController: DocumentCaptureSessionDelegate {

    public func readyToCapture() {
        DispatchQueue.main.async {
            if self.messageLayer != nil {
                self.messageLayer.string = self.docOptions.textForState(.capture)
                if self.docOptions.autoCapture {
                    self.setLookFromState(state: .capture)
                } else {
                    self.setMessageDefaultSettings()
                }
                self.captured = true
            }
        }
    }

    public func documentCaptured(image: UIImage, barcodeString: String?) {
        let data = CameraMetaData().setCaptureType(captureType: docOptions.autoCapture ? "AUTO" : "TAP")
        let result = ImagePreparation.createCameraImage(image: rotateImage(image: image),
                                                        data: data)
        navigationController?.popViewController(animated: true)
        delegate?.onCaptured(image: result, barcodeString: barcodeString)
    }

}

 //MARK: - FrameAnalysisDelegate

extension DocumentCameraViewController: FrameAnalysisDelegate {

    public func onFrameAvailable(frameResult: FrameResult, points: [CGPoint]?) {
        if cameraPreviewView == nil
            || messageLayer == nil
            || captured
            || !autoCapture
            || captureSession.isInterrupted {
            return
        }

        switch frameResult {
        case .noDocument:
            transitionTo(state: .align, message: docOptions.textForState(.align))
        case .smallDocument:
            transitionTo(state: .moveCloser, message: docOptions.textForState(.moveCloser))
        case .badAspectRatio:
            transitionTo(state: .moveCloser, message: docOptions.textForState(.moveCloser))
        case .documentNotInFrame:
            transitionTo(state: .tooClose, message: docOptions.textForState(.tooClose))
        case .goodDocument:
            guard let points = points, points.count == 4, autoCapture else {
                return
            }
            
            let scaledPoints = scalePoints(points: points)
            setPath(points: scaledPoints)
            if !isHoldSteady {
                setLookFromState(state: .hold)
                if isDocumentMoved(points: scaledPoints) {
                    transitionTo(state: .steady, message: docOptions.textForState(.steady))
                } else if !captured {
                    triggerCapture()
                }
                currentPoints = scaledPoints
            }
        }
    }

}

// MARK: - AutoCaptureDelegate

extension DocumentCameraViewController: AutoCaptureDelegate {
    
    public func getAutoCapture() -> Bool {
        return docOptions.autoCapture
    }
    
    public func setAutoCapture(autoCapture: Bool) {
        self.autoCapture = autoCapture
        if !autoCapture {
            DispatchQueue.main.async {
                self.messageLayer.string = self.docOptions.textForManualCapture
            }
        }
    }
    
}

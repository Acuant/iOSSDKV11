//
//  CameraController.swift
//  SampleApp
//
//  Created by John Moon 2/20/20.
//  Copyright © 2020 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantImagePreparation
import AcuantCommon

@objcMembers public class MrzCameraViewController: CameraViewController {
    private var currentPoints: [CGPoint?] = [nil, nil, nil, nil]
    private var threshold = 25
    private var isCaptured = false
    private var mrzResult: AcuantMrzResult?
    private var dotCount = 0
    private var counter: Timer?
    private let mrzOptions: MrzCameraOptions

    public weak var delegate: MrzCameraViewControllerDelegate?

    public init(options: MrzCameraOptions) {
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
        let captureSession = MrzCaptureSession(captureDevice: captureDevice)
        mrzOptions = options
        super.init(options: options, captureSession: captureSession)
        captureSession.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        messageLayer.isHidden = true
    }

    override func onCameraInterrupted() {
        messageLayer.isHidden = false
        messageLayer.string = options.textForCameraPaused
        imageLayer?.isHidden = true
    }
    
    override func onCameraInterruptionEnded() {
        messageLayer.isHidden = true
        imageLayer?.isHidden = false
    }
    
    override func onBackTapped() {
        delegate?.onCaptured(mrz: nil)
    }
    
    override func onPreviewCreated() {
        cameraPreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    private func handleUi(color: CGColor, message: String = "", points: [CGPoint]? = nil, shouldShowOverlay: Bool = false) {
        cornerLayer.setColor(color: color)
        
        if message.isEmpty {
            imageLayer?.isHidden = false
            messageLayer.isHidden = true
            if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
                cornerLayer.setHorizontalDefaultCorners(frame: view.frame)
            } else {
                cornerLayer.setDefaultCorners(frame: view.frame)
            }
            detectionBoxLayer.hideBorder()
            counter?.invalidate()
            counter = nil
        } else {
            imageLayer?.isHidden = true
            messageLayer.isHidden = false
            messageLayer.string = message
            updateCorners(points: points)
            if let orientation = view.window?.interfaceOrientation, orientation.isLandscape {
                messageLayer.setDefaultSettings(frame: view.frame)
            } else {
                messageLayer.setVerticalDefaultSettings(frame: view.frame)
            }
            
            if shouldShowOverlay {
                detectionBoxLayer.showBorder(color: color)
            } else {
                detectionBoxLayer.hideBorder()
            }
        }
    }
    
    private func updateCorners(points: [CGPoint]?) {
        guard let points = points, points.count == 4 else {
            return
        }

        let convertedPoints = scalePoints(points: points)
        let openSquarePath = UIBezierPath()
        openSquarePath.move(to: convertedPoints[0])
        openSquarePath.addLine(to: convertedPoints[1])
        openSquarePath.addLine(to: convertedPoints[2])
        openSquarePath.addLine(to: convertedPoints[3])
        openSquarePath.addLine(to: convertedPoints[0])

        detectionBoxLayer.path = openSquarePath.cgPath
        cornerLayer.setCorners(point1: convertedPoints[0],
                               point2: convertedPoints[1],
                               point3: convertedPoints[2],
                               point4: convertedPoints[3])
    }
    
    public func exitTimer() {
        if let result = self.mrzResult {
            counter?.invalidate()
            captureSession.stop()
            delegate?.onCaptured(mrz: result)
        }
    }
    
    private func isInRange(point: CGPoint) -> Bool {
        return (point.x >= 0 && point.x <= cameraPreviewView.frame.width)
        && (point.y >= 0 && point.y <= cameraPreviewView.frame.height)
    }
    
    private func isOutsideView(points: [CGPoint]?) -> Bool {
        guard let points = points, points.count == 4 else {
            return false
        }
        
        let scaledPoints = scalePoints(points: points)
        for i in scaledPoints {
            if !isInRange(point: i) {
                return true
            }
        }
        return false
    }
    
    private func isDocumentMoved(newPoints: [CGPoint]) -> Bool {
        guard newPoints.count == currentPoints.count else {
            return false
        }
        
        for i in 0..<currentPoints.count {
            if Int(abs(currentPoints[i]!.x - newPoints[i].x)) > threshold || Int(abs(currentPoints[i]!.y - newPoints[i].y)) > threshold {
                return true
            }
        }
        return false
    }
}

// MARK: - MrzCaptureSessionDelegate

extension MrzCameraViewController: MrzCaptureSessionDelegate {

    public func onCaptured(state: MrzCameraState, result: AcuantMrzResult?, points: [CGPoint]?) {
        DispatchQueue.main.async {
            guard !self.captureSession.isInterrupted else { return }

            if self.cameraPreviewView == nil ||
                self.messageLayer == nil ||
                self.cameraPreviewView.videoPreviewLayer.isHidden ||
                self.isCaptured {
                return
            }

            if self.isOutsideView(points: points) {
                self.mrzResult = nil
                self.handleUi(color: self.mrzOptions.colorForState(.align), message: self.mrzOptions.textForState(.align))
            } else {
                if let parsedResut = result {
                    self.mrzResult = parsedResut
                }

                let message = self.mrzOptions.textForState(state)
                let color = self.mrzOptions.colorForState(state)

                switch state {
                case .none:
                    self.mrzResult = nil
                    self.handleUi(color: color, message: message)
                case .align:
                    self.handleUi(color: color, message: message)
                case .moveCloser:
                    self.handleUi(color: color, message: message, points: points)
                case .tooClose:
                    self.handleUi(color: color, message: message, points: points)
                case .reposition:
                    self.handleUi(color: color, message: message, points: points, shouldShowOverlay: true)
                case .good, .captured:
                    if self.mrzResult != nil {
                        self.isCaptured = true
                        self.handleUi(color: color,
                                      message: message,
                                      points: points,
                                      shouldShowOverlay: true)
                        self.counter = Timer.scheduledTimer(timeInterval: 0.8,
                                                            target: self,
                                                            selector: #selector(self.exitTimer),
                                                            userInfo: nil,
                                                            repeats: false)
                    } else {
                        self.handleUi(color: color, message: message, points: points, shouldShowOverlay: true)
                    }
                }
            }
        }
    }

}

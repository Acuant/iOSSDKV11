//
//  CaptureSession.swift

//
//  Created by Tapas Behera on 7/9/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AcuantCommon
import AcuantImagePreparation

@objcMembers public class AcuantMrzCaptureSession: AVCaptureSession, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureDevice: AVCaptureDevice
    private let detector = AcuantOcrDetector()
    private let parser = AcuantMrzParser()
    private let context = CIContext()
    private var cropping = false
    private var callback: ((AcuantMrzCameraController.MrzCameraState, AcuantMrzResult?, Array<CGPoint>?) -> Void)?
    
    public init(captureDevice: AVCaptureDevice, userCallback:((AcuantMrzCameraController.MrzCameraState, AcuantMrzResult?, Array<CGPoint>?) -> Void)? = nil) {
        self.captureDevice = captureDevice
        self.callback = userCallback
    }
    
    public func start() {
        self.automaticallyConfiguresApplicationAudioSession = false
        self.usesApplicationAudioSession = false
        self.sessionPreset = AVCaptureSession.Preset.photo

        self.setFocusMode()
        self.addCaptureDevice()
        self.addVideoOutput()
        self.startRunning()
    }
    
    private func setFocusMode(){
        if(self.captureDevice.isFocusModeSupported(.continuousAutoFocus)) {
            try? self.captureDevice.lockForConfiguration()
            self.captureDevice.focusMode = .continuousAutoFocus
            self.captureDevice.unlockForConfiguration()
        }
    }
    
    private func addCaptureDevice(){
        do {
            let input = try AVCaptureDeviceInput(device: self.captureDevice)
            if(self.canAddInput(input)){
                self.addInput(input)
            }
        } catch _ as NSError {
            return
        }
    }
    
    private func addVideoOutput(){
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let frameQueue = DispatchQueue(label: "com.acuant.frame.queue",qos:.userInteractive,attributes:.concurrent)
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        if(self.canAddOutput(videoOutput)){
            self.addOutput(videoOutput)
        }
    }
    
    
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let frameQueue = DispatchQueue(label: "com.acuant.image.queue",attributes:.concurrent)
        frameQueue.async {
            if self.cropping || !self.detector.isInitalized {
                return
            }
            
            if let frame = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) {
                self.cropping = true
                
                var scaledPoints : Array<CGPoint> = Array<CGPoint>()
                var state = AcuantMrzCameraController.MrzCameraState.None
                var result: AcuantMrzResult?

                if let croppedFrame = self.detectImage(image: frame),
                   self.isMrzAligned(croppedFrame.points),
                   let img = croppedFrame.image {

                    result = self.executeOCRAndParseMrzResult(image: img)
                    state = self.getMrzState(points:croppedFrame.points, imgSize: img.size, frameSize: frame.size)
                    scaledPoints = self.getScaledPoints(points: croppedFrame.points, frameSize: frame.size)
                }
                
                if let cb = self.callback {
                    cb(state, result, scaledPoints)
                }
                self.cropping = false
            }
        }
    }
    
    private func getScaledPoints(points: Array<CGPoint>, frameSize: CGSize) -> Array<CGPoint>{
        var scaledPoints : Array<CGPoint> = Array<CGPoint>()
        
        points.forEach{ point in
            var scaled: CGPoint = CGPoint()
            scaled.x = point.x/frameSize.width as CGFloat
            scaled.y = point.y/frameSize.height  as CGFloat
            scaledPoints.append(scaled)
        }
        return scaledPoints
    }
    
    private func getMrzState(points:Array<CGPoint>, imgSize: CGSize, frameSize: CGSize) -> AcuantMrzCameraController.MrzCameraState{
        var state : AcuantMrzCameraController.MrzCameraState = .None
                
        if(!self.isCorrectAspectRatio(size: imgSize) || self.isMrzTilted(points: points)){
            state = .Align
        }
        else if(self.isMrzTooFar(size: imgSize, frameSize: frameSize)){
            state = .MoveCloser
        }
        else if (self.isMrzTooClose(size: imgSize, frameSize: frameSize)){
            state = .TooClose
        }
        else{
            state = .Good
        }
        return state
    }
    
    private func executeOCRAndParseMrzResult(image: UIImage) -> AcuantMrzResult?{
        var result: AcuantMrzResult?
        if let mrz = self.detector.detect(image: image){
            if let parsed = self.parser.parseMrz(mrz: mrz){
                if(parsed.checkSumResult1 && parsed.checkSumResult2
                    && parsed.checkSumResult3 && parsed.checkSumResult4
                    && parsed.checkSumResult5)
                {
                    result = parsed
                }
            }
        }
        return result
    }
    
    private func isMrzTooClose(size:CGSize, frameSize: CGSize) -> Bool{
        return max(size.width, size.height) >= 0.95 * max(frameSize.width, frameSize.height)
    }
    
    private func isMrzTooFar(size:CGSize, frameSize: CGSize) -> Bool{
        return max(size.width, size.height) <= 0.65 * max(frameSize.width, frameSize.height)
    }
    
    private func isCorrectAspectRatio(size:CGSize) -> Bool{
        let aspectRatio = size.width/size.height
        return (4...10 ~= aspectRatio)
    }
    
    private func isMrzTilted(points:Array<CGPoint>) -> Bool{
        let diff1 = self.getDistance(p1: points[0], p2: points[2])
        let diff2 = self.getDistance(p1: points[1], p2: points[3])
        let diff3 = abs(diff2 - diff1)
        return (diff3 > 5)
    }
    
    private func getDistance(p1: CGPoint, p2: CGPoint) -> Int{
        return Int(sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2)))
    }
    
    private func isMrzAligned(_ points: [CGPoint]) -> Bool {
        guard points.count == 4 else {
            return false
        }

        return abs(points[1].x - points[3].x) > abs(points[1].y - points[3].y)
    }

    public func stopCamera(){
        self.stopRunning()
    }
    
    func detectImage(image:UIImage)->Image?{
        let detectData  = DetectData.newInstance(image: image)
        
        let croppedImage = ImagePreparation.cropMrz(detectData: detectData)
        return croppedImage
    }
}

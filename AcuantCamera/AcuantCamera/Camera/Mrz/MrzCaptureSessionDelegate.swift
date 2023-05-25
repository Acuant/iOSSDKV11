//
//  MrzCaptureSessionDelegate.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 13/12/22.
//  Copyright © 2022 Acuant. All rights reserved.
//

@objc public protocol MrzCaptureSessionDelegate {
    func onCaptured(state: MrzCameraState, result: AcuantMrzResult?, points: [CGPoint]?)
}

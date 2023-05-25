//
//  FrameAnalysisDelegate.swift
//  AcuantCamera
//
//  Created by John Moon local on 3/19/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//
import UIKit
import Foundation

@objc public protocol FrameAnalysisDelegate {
    func onFrameAvailable(frameResult: FrameResult, points: [CGPoint]?)
}

@objc public enum FrameResult: Int {
    case noDocument, smallDocument, badAspectRatio, goodDocument, documentNotInFrame
}

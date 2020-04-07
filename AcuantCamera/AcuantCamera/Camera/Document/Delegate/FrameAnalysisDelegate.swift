//
//  FrameAnalysisDelegate.swift
//  AcuantCamera
//
//  Created by John Moon local on 3/19/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//
import UIKit
import Foundation

@objc public protocol FrameAnalysisDelegate{
    func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?)
}

@objc public enum FrameResult : Int{
    case NO_DOCUMENT, SMALL_DOCUMENT, BAD_ASPECT_RATIO, GOOD_DOCUMENT, DOCUMENT_NOT_IN_FRAME
}

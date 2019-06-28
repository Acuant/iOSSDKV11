//
//  FrameAnalysisDelegate.swift
//  AcuantCamera
//
//  Created by John Moon local on 3/19/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//
import UIKit

public protocol FrameAnalysisDelegate{
    func onFrameAvailable(frameResult: FrameResult, points: Array<CGPoint>?)
}

public enum FrameResult{
    case NO_DOCUMENT, SMALL_DOCUMENT, BAD_ASPECT_RATIO, GOOD_DOCUMENT
}

//
//  FrameAnalysisDelegate.swift
//  AcuantCamera
//
//  Created by John Moon local on 3/19/19.
//  Copyright © 2019 Tapas Behera. All rights reserved.
//

public protocol FrameAnalysisDelegate{
    func onFrameAvailable(frameResult: FrameResult)
}

public enum FrameResult{
    case NO_DOCUMENT, SMALL_DOCUMENT, BAD_ASPECT_RATIO, GOOD_DOCUMENT
}

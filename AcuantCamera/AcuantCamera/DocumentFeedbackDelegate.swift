//
//  DocumentFeedbackDelegate.swift
//  AcuantMobileSDK
//
//  Created by Tapas Behera on 9/13/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//


public enum DocumentFeedback {
    case NoDocument
    case SmallDocument
    case BadDocument
    case BadAspectRatio
    case GoodDocument
    case CaptureStarted
    case CaptureFinished
}

public protocol DocumentFeedbackDelegate {
    func documentFeedback(feedback:DocumentFeedback)
}


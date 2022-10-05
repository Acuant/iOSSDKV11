//
//  StringExtn.swift
//  AcuantCamera
//
//  Created by Federico Nicoli on 10/6/21.
//  Copyright © 2021 Tapas Behera. All rights reserved.
//

extension String {
    static let kUISupportedInterfaceOrientations = "UISupportedInterfaceOrientations"
    static let kUIInterfaceOrientationPortrait = "UIInterfaceOrientationPortrait"

    func size(ofFont font: UIFont) -> CGSize {
        return (self as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
    }
}

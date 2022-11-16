//
//  FaceCaptureLanguageManager.swift
//  AcuantFaceCapture
//
//  Created by Ruzanna Sedrakyan on 16.11.22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import UIKit


// MARK: - Custom Localization

open class FaceCaptureLanguageManager {
    static let shared = FaceCaptureLanguageManager()

    var langCode: String?
    private(set) var currentLanguage: String

    private init() {
        if let appLanguage = langCode {
            currentLanguage = appLanguage
        } else {
            currentLanguage = Locale.current.languageCode!
        }
    }
    
    public static func localizedString(_ key: String, comment: String = "") -> String {
        let bundle = Bundle.main
        guard let path = bundle.path(forResource: FaceCaptureLanguageManager.shared.currentLanguage, ofType: "lproj"),
            let string = Bundle(path: path)?.localizedString(forKey: key, value: "", table: "") else {
                return NSLocalizedString(key, comment: comment)
        }
        return string
    }
    
}

extension String {
    var localizedFaceCaptureString: String {
        return FaceCaptureLanguageManager.localizedString(self)
    }
}

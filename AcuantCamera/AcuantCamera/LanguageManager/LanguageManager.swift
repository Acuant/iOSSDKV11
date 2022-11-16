//
//  LanguageManager.swift
//  AcuantCamera
//
//  Created by Ruzanna Sedrakyan on 16.11.22.
//  Copyright © 2022 Acuant. All rights reserved.
//

import UIKit

// MARK: - Custom Localization

    open class DocLanguageManager {
    static let shared = DocLanguageManager()

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
        guard let path = bundle.path(forResource: DocLanguageManager.shared.currentLanguage, ofType: "lproj"),
            let string = Bundle(path: path)?.localizedString(forKey: key, value: "", table: "") else {
                return NSLocalizedString(key, comment: comment)
        }
        return string
    }
    
}

extension String {
     public var localizedDocString: String {
        return DocLanguageManager.localizedString(self)
    }
}


//
//  UIScreenExtn.swift
//  idScan Go
//
//  Created by Tapas Behera on 10/22/18.
//  Copyright © 2018 com.idscan. All rights reserved.
//

import UIKit

internal extension UIScreen {
    
    func sizeOfSafeArea()->CGSize{
        return CGSize.init(width: widthOfSafeArea(), height: heightOfSafeArea())
    }
    
    func widthOfSafeArea() -> CGFloat {
        
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }
        
        if #available(iOS 11.0, *) {
            let leftInset = rootView.safeAreaInsets.left
            
            let rightInset = rootView.safeAreaInsets.right
            
            return rootView.bounds.width - leftInset - rightInset
        } else {
            return rootView.bounds.width
        }
    }
    
    func heightOfSafeArea() -> CGFloat {
        
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }
        
        if #available(iOS 11.0, *) {
            let topInset = rootView.safeAreaInsets.top
            
            let bottomInset = rootView.safeAreaInsets.bottom
            
            return rootView.bounds.height - topInset - bottomInset
        } else {
            return rootView.bounds.height
        }
    }
}

//
//  ViewControllerUtils.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import Foundation
import UIKit

class ViewControllerUtils {
    
    let container: UIView = UIView()
    let loadingView: UIView = UIView()
    let messageView : UILabel = UILabel()
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    /*
     Show customized activity indicator,
     actually add activity indicator to passing view
     
     @param uiView - add activity indicator to this view
     */
    func showActivityIndicator(uiView: UIView,text:String) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColorFromHex(rgbValue: 0xffffff, alpha: 0.3)
        
        loadingView.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        
        activityIndicator.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
        
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        if(text != ""){
            loadingView.frame = CGRect.init(x: 0, y: 0, width: 120, height: 100)
            loadingView.center = uiView.center
            activityIndicator.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
            messageView.frame = CGRect.init(x:activityIndicator.frame.origin.x,y:activityIndicator.frame.origin.y+activityIndicator.frame.size.height+10,width:120,height:20)
            
            messageView.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2 + activityIndicator.frame.size.height/2+5)
            messageView.text = text
            messageView.textColor = UIColor.lightGray
            messageView.textAlignment = NSTextAlignment.center
            loadingView.addSubview(messageView)
        }
        
        loadingView.addSubview(activityIndicator)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        activityIndicator.startAnimating()
    }
    
    /*
     Hide activity indicator
     Actually remove activity indicator from its super view
     
     @param uiView - remove activity indicator from this view
     */
    func hideActivityIndicator(uiView: UIView) {
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
    }
    
    /*
     Define UIColor from hex value
     
     @param rgbValue - hex color value
     @param alpha - transparency level
     */
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
}


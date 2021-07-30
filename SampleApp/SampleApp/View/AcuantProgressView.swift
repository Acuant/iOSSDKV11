//
//  AcuantProgressView.swift
//  SampleApp
//
//  Created by John Moon local on 7/31/19.
//  Copyright © 2019 com.acuant. All rights reserved.
//
import Foundation
import UIKit

@objcMembers class AcuantProgressView: UIView {
    var shouldSetupConstraints = true
    var loadingView: UIView!
    var messageView : UILabel!
    var activityIndicator: UIActivityIndicatorView!
    
    init(frame: CGRect, center: CGPoint) {
        super.init(frame: frame)
        self.frame = frame
        self.center = center
        self.backgroundColor = UIColorFromHex(rgbValue: 0xffffff, alpha: 0.3)
        
        loadingView = UIView()
        loadingView.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        
        loadingView.center = center
        loadingView.backgroundColor = UIColorFromHex(rgbValue: 0x444444, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
        
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        //if(text != ""){
        loadingView.frame = CGRect.init(x: 0, y: 0, width: 120, height: 100)
        loadingView.center = center
        activityIndicator.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        messageView = UILabel()
        messageView.frame = CGRect.init(x:activityIndicator.frame.origin.x,y:activityIndicator.frame.origin.y+activityIndicator.frame.size.height+10,width:120,height:20)
        
        messageView.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2 + activityIndicator.frame.size.height/2+5)
        messageView.textColor = UIColor.lightGray
        messageView.textAlignment = NSTextAlignment.center
        loadingView.addSubview(messageView)
       // }
        
        loadingView.addSubview(activityIndicator)
        self.addSubview(loadingView)
    }
    
    func startAnimation(){
        activityIndicator.startAnimating()
    }
    
    func stopAnimation(){
        activityIndicator.stopAnimating()
    }
    
    func update(frame: CGRect, center: CGPoint) {
        self.frame = frame
        self.center = center
        loadingView.center = center
        activityIndicator.center = CGPoint.init(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        messageView.frame = CGRect(x: activityIndicator.frame.origin.x,
                                   y: activityIndicator.frame.origin.y+activityIndicator.frame.size.height+10,
                                   width: 120,
                                   height: 20)
        messageView.center = CGPoint(x: loadingView.frame.size.width / 2,
                                     y: loadingView.frame.size.height / 2 + activityIndicator.frame.size.height/2+5)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            // AutoLayout constraints
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
    
    private func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
}

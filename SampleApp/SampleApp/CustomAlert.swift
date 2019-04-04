//
//  CustomAlert.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit

class CustomAlerts{
    static func displayError(message:String){
        DispatchQueue.main.async{
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            delegate.showAlertGlobally(alert)
        }
    }
    
    static func display(message:String,action:UIAlertAction){
        DispatchQueue.main.async{
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(action)
            let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            delegate.showAlertGlobally(alert)
        }
    }
    
}


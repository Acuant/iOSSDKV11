//
//  ConfirmationViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/11/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit
import AcuantImagePreparation
import AcuantDocumentProcessing
import AcuantCommon
import AcuantCamera

class ConfirmationViewController: UIViewController {
    
    public var acuantImage: AcuantImage?
    public var barcodeCaptured : Bool = false
    public var barcodeString : String? = nil
    
    @IBOutlet var retryButton: UIButton!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!

    @IBAction func confirmTapped(_ sender: Any) {
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        self.navigationController?.popViewController(animated: true)
        rootVC.confirmImage(image: acuantImage!)
        
    }
    
    @IBAction func retryTapped(_ sender: Any) {
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        self.navigationController?.popViewController(animated: true)
        rootVC.retryCapture()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView?.image = acuantImage?.image
        var text : String = "Please ensure all text is visible\n"
        if(acuantImage?.image == nil){
            text = "Could not crop image\nPlease hold steady and retry\nPlease make sure there is enough ambient light and retry\n"
        }
        if(acuantImage?.image != nil){
            text = text + "Sharpness Grade : \(acuantImage!.sharpness)\n"
            text = text + "Is Blurry : \(acuantImage!.sharpness < CaptureConstants.SHARPNESS_THRESHOLD)\n"
            text = text + "Glare Grade : \(acuantImage!.glare)\n"
            text = text + "Has Glare : \(acuantImage!.glare < CaptureConstants.GLARE_THRESHOLD)\n"
            text = text + "DPI : \(String(describing: acuantImage!.dpi))\n"
        }
        if(barcodeCaptured && barcodeString != nil){
            let len = (barcodeString?.count)!*25/100
            let index = barcodeString?.index((barcodeString?.startIndex)!, offsetBy: len)
            text = text + "Barcode : \(barcodeString!.prefix(upTo: index!))..."
        }
        
        textView.text = text
        textView.isEditable = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

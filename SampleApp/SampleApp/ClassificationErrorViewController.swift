//
//  ClassificationErrorViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 8/16/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit

class ClassificationErrorViewController: UIViewController {
    @IBOutlet var retryButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    public var image : UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        if(image != nil){
            imageView.image = image
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func retryTapped(_ sender: Any) {
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        self.navigationController?.popViewController(animated: true)
        rootVC.retryClassification()
    }

}

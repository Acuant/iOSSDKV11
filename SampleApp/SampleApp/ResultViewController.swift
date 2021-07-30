//
//  ResultViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/12/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit
import AcuantImagePreparation

class ResultViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet var frontImage: UIImageView!
    @IBOutlet var backImage: UIImageView!
    @IBOutlet var faceImage: UIImageView!
    @IBOutlet var signImage: UIImageView!
    @IBOutlet weak var faceCapturedImage: UIImageView!
    
    public var data: [String]?
    public var frontImageUrl: String?
    public var backImageUrl: String?
    public var faceImageUrl: String?
    public var signImageUrl: String?
    
    public var front: UIImage?
    public var back: UIImage?
    public var faceImageCaptured: UIImage?

    public var username: String?
    public var password: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        if let frontImageUrl = self.frontImageUrl {
            frontImage.downloadedFrom(urlStr: frontImageUrl, username: username!, password: password!)
        }
        
        if let backImageUrl = self.backImageUrl {
            backImage.downloadedFrom(urlStr: backImageUrl, username: username!, password: password!)
        }
        
        if let faceImageUrl = self.faceImageUrl {
            faceImage.downloadedFrom(urlStr: faceImageUrl, username: username!, password: password!)
        }
        
        if let signImageUrl = self.signImageUrl {
            signImage.downloadedFrom(urlStr: signImageUrl, username: username!, password: password!)
        }
        
        if backImageUrl == nil {
            backImage.removeFromSuperview()
            if faceImageCaptured == nil {
                faceImage.leadingAnchor.constraint(equalTo: frontImage.trailingAnchor, constant: 10).isActive = true
            } else {
                frontImage.trailingAnchor.constraint(equalTo: faceCapturedImage.leadingAnchor, constant: 10).isActive = true
            }
        }
        
        if let frontCapturedImage = self.faceImageCaptured {
            faceCapturedImage.image = frontCapturedImage
        } else {
            faceCapturedImage.removeFromSuperview()
            if backImageUrl == nil {
                faceImage.leadingAnchor.constraint(equalTo: frontImage.trailingAnchor, constant: 10).isActive = true
            } else {
                faceImage.leadingAnchor.constraint(equalTo: backImage.trailingAnchor, constant: 10).isActive = true
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(data == nil){
            return 0
        }
        return data!.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.estimatedRowHeight = 44.0;
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.text = data?[indexPath.row]
        cell.textLabel?.textColor = UIColor.black
        return cell
    }
    
}

extension UIImageView {
    func downloadedFrom(urlStr:String,username:String,password:String) {
        let loginData = String(format: "%@:%@", username, password).data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        
        // create the request
        let url = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let httpURLResponse = response as? HTTPURLResponse
            if(httpURLResponse?.statusCode == 200 && data != nil){
                let downloadedImage = UIImage(data: data!)
                DispatchQueue.main.async() { () -> Void in
                    self.image = downloadedImage
                    self.isHidden=false;
                }
            }else {
                return
            }
            }.resume()
    }
    
}

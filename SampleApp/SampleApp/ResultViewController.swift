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
    
    public var data:[String]? = nil
    public var frontImageUrl : String? = nil
    public var backImageUrl : String? = nil
    public var faceImageUrl : String? = nil
    public var signImageUrl : String? = nil
    
    public var front : UIImage? = nil
    public var back : UIImage? = nil
    public var faceImageCaptured : UIImage? = nil

    public var username : String? = nil
    public var password : String? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        if(frontImageUrl != nil){
            frontImage.downloadedFrom(urlStr: frontImageUrl!, username: username!, password: password!)
        }
        if(backImageUrl != nil){
            backImage.downloadedFrom(urlStr: backImageUrl!, username: username!, password: password!)
        }
        
        if(faceImageUrl != nil){
            faceImage.downloadedFrom(urlStr: faceImageUrl!, username: username!, password: password!)
        }
        
        if(signImageUrl != nil){
            signImage.downloadedFrom(urlStr: signImageUrl!, username: username!, password: password!)
        }
        
        if(front != nil){
            frontImage.image = front
        }
        
        if(back != nil){
            backImage.image = back
        }
        
        if let frontCapturedImage = self.faceImageCaptured{
            faceCapturedImage.image = frontCapturedImage
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
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

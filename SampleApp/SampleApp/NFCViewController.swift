//
//  NFCViewController.swift
//  AcuantNFC
//
//  Created by Tapas Behera on 7/9/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import CoreNFC
import AcuantCamera
import AcuantEchipReader

/// - Tag: NFCViewController
class NFCViewController: UIViewController, UITextFieldDelegate, OzoneServiceDelegate {
    
    @IBOutlet weak var passportNumberTextView: UITextField!
    
    @IBOutlet weak var expiryTextView: UITextField!
    @IBOutlet weak var dobTextView: UITextField!
    
    
    // MARK: - Properties
    public var result : AcuantMrzResult!
    private let reader: IAcuantEchipReader = AcuantEchipReader()

    @IBOutlet weak var assistanceLabel: UILabel!
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passportNumberTextView.delegate = self
        expiryTextView.delegate = self
        dobTextView.delegate = self
        
        self.passportNumberTextView.text = result.passportNumber
        self.expiryTextView.text = result.passportExpiration
        self.dobTextView.text = result.dob
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(tapGestureRecogniser)
        
        self.setDataPageAlert()
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func setDataPageAlert(){
        if let mapped = AcuantEchipReader.getPositionOfChip(countryCode: result.country.uppercased()){
            if(mapped.compare("unknown", options: NSString.CompareOptions.caseInsensitive) == .orderedSame){
                self.showAlert(title: "Chip Location", message: "The passport chip is unkown for this country."){
                    self.startScanning()
                }
            }
            else{
                let description = "The passport chip will be on the \(mapped)."
                self.showAlert(title: "Chip Location", message: description){
                    self.startScanning()
                }
                assistanceLabel.text! += "\(description)"
            }
        }
    }
    
    func onSuccess() {
        print("success")
    }
    
    func onFail() {
        print("fail")
    }
    
    @objc func tap(sender: UITapGestureRecognizer) {
        self.startScanning()
    }
    
    private func startScanning(){
        if let error = validInput(){
            showAlert(title: "Error", message: error)
        }
        else{
            let request = AcuantEchipSessionRequest(passportNumber: passportNumberTextView.text!, dateOfBirth: dobTextView.text!, expiryDate:expiryTextView.text!)
            
            self.reader.readNfcTag(request: request, customDisplayMessage: customDisplayMessage){ [weak self]
                (model, error) in
                if let result = model{
                    DispatchQueue.main.async {
                        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                        let vc = storyBoard.instantiateViewController(withIdentifier: "NFCResultViewController") as! NFCResultViewController
                        vc.passport = result
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
                else{
                    if let err = error{
                        self?.showAlert(title: "Error", message: "Error has occured. code:\(err.errorCode), desc:\(err.errorDescription ?? "")")
                    }
                    else{
                        //user canceled
                    }
                    
                }
            }
        }
    }
    
    private let customDisplayMessage : ((AcuantEchipDisplayMessage) -> String?) =  {
        message in
    
        switch message {
            case .requestPresentPassport:
                return "Hold your iPhone near an NFC enabled passport."
            case .authenticatingWithPassport(let progress):
                let progressString = handleProgress(percentualProgress: progress)
                return "Authenticating with passport.....\n\n\(progressString)"
            case .readingDataGroupProgress(let dataGroup, let progress):
                let progressString = handleProgress(percentualProgress: progress)
                return "Reading \(dataGroup).....\n\n\(progressString)"
            case .error:
                return "Sorry, there was a problem reading the passport. Please try again"
            case .successfulRead:
                return "Passport read successfully"
            case .authenticatingExtractedData:
                return "Authenicating with Ozone"
            }
    }
    
    private class func handleProgress(percentualProgress: Int) -> String {
        let p = (percentualProgress/20)
        let full = String(repeating: "🟢 ", count: p)
        let empty = String(repeating: "⚪️ ", count: 5-p)
        return "\(full)\(empty)"
    }
    
    private func showAlert(title:String, message:String, userAction:(() -> ())? = nil){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            // Add "OK" Button to alert, pressing it will bring you to the settings app
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                if let act = userAction{
                    act()
                }
            }))
            // Show the alert with animation
            self.present(alert, animated: true)
        }
    }
    
    func validInput()->String?{
        let passportNumber = passportNumberTextView.text!
        let dateOfBirth = dobTextView.text!
        let expiryDate = expiryTextView.text!
        if(dateOfBirth.count != 6){
            return "invalid date of birth"
        }
        if(expiryDate.count != 6){
            return "invalid date of expiry"
        }
        if(passportNumber.count == 0){
            return "passportNumber cannot be empty"
        }
        return nil
    }
    
}


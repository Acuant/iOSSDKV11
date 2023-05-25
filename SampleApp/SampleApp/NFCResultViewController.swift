//
//  ResultViewController.swift
//  AcuantNFC
//
//  Created by Tapas Behera on 7/9/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import AcuantEchipReader

class CustomCell: UITableViewCell {
    public weak var cellLabel: UILabel!
    public weak var cellDescription: UILabel!

    init(frame: CGRect, title: String) {
        super.init(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")

        cellLabel = UILabel(frame: CGRect(x: self.frame.width - 100, y: 10, width: 100.0, height: 40))
        cellLabel.textColor = UIColor.black
        
        cellDescription = UILabel(frame: CGRect(x: self.frame.width - 100, y: 10, width: 100.0, height: 40))
        cellDescription.textColor = UIColor.black

        cellLabel.text = title
        addSubview(cellLabel)
        addSubview(cellDescription)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}

class ResultTableViewController : UITableViewController{
    public var result: [String] = []

    // 1
     override func numberOfSections(in tableView: UITableView) -> Int {
         return 1
     }

     // 2
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return result.count
     }

     // 3
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cellIdentifier = "CustomCell"
         
         guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CustomCell  else {
                fatalError("The dequeued cell is not an instance of MealTableViewCell.")
            }
         
         cell.cellLabel.text = result[indexPath.row]

         return cell
     }
     
}

@available (iOS 13, *)
class NFCResultViewController: UIViewController{
    
    public var passport : AcuantPassportModel!
    
    @IBOutlet weak var faceImgeView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    public var data : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        faceImgeView.image = passport.image
        data.append("\n Document Number  : " + passport.documentNumber)
        data.append("\n Nationality  : " + passport.nationality)
        data.append("\n First Name  : " + passport.firstName )
        data.append("\n Last Name  : " + passport.lastName)
        data.append("\n Gender  : " + passport.gender)
        if let age = passport.age {
            data.append("\n Age  : \(age)")
        }
        
        if let isExpired = passport.isExpired {
            data.append("\n Is Expired  : \(isExpired ? "True" : "False")")
        }
        
        data.append("\n Date of Birth  : " + passport.dateOfBirth)
        data.append("\n Expiry Date  : " + passport.documentExpiryDate)
        data.append("\n Document Type  : " + passport.documentType)
        if passport.translatedDocumentType != TranslatedDocumentType.default {
            data.append("\n Translated Document Type  : " + passport.translatedDocumentType.rawValue)
        }
        data.append("\n Issuing Authority  : " + passport.issuingAuthority)
        data.append("\n Data Hash  : "  + (passport.passportDataValid ? "True" : "False"))

        if passport.passportSigned != OzoneResultStatus.notPerformed {
            data.append("\n Document Signer  (Ozone): "  + (passport.passportSigned == OzoneResultStatus.success ? "True" : "False"))
        }

        if passport.passportCountrySigned != OzoneResultStatus.notPerformed {
            data.append("\n Country Signer (Ozone): "  +  (passport.passportCountrySigned == OzoneResultStatus.success ? "True" : "False"))
        }

        if passport.BACStatus != AuthStatus.skipped {
            data.append("\n BAC Authentication: "  +  (passport.BACStatus == AuthStatus.success ? "True" : "False"))
        }

        if passport.PACEStatus != AuthStatus.skipped {
            data.append("\n PACE Authentication: "  +  (passport.PACEStatus == AuthStatus.success ? "True" : "False"))
        }

        if passport.chipAuthenticationStatus != AuthStatus.skipped {
            data.append("\n Chip Authentication: " + (passport.chipAuthenticationStatus == .success ? "True" : "False"))
        }

        if passport.activeAuthenticationStatus != AuthStatus.skipped {
            data.append("\n Active Authentication: " + (passport.activeAuthenticationStatus == .success ? "True" : "False"))
        }
        tableView.reloadData()
   
    }
    
    private func mapOzoneResult(result: OzoneResultStatus) -> String {
        switch result {
        case .success:
            return "True"
        case .failed:
            return  "False"
        default:
            return "Unknown"
        }
    }

 
    @IBAction func backTapped(_ sender: Any) {
        
        self.removeFromParent()
    }
}

@available (iOS 13, *)
extension NFCResultViewController: UITableViewDataSource,UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textColor = UIColor.black
        return cell
    }
}

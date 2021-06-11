//
//  MrzHelpViewController.swift
//  SampleApp
//
//  Created by Federico Nicoli on 31/5/21.
//  Copyright © 2021 com.acuant. All rights reserved.
//

import UIKit
import AcuantCamera

protocol MrzHelpViewControllerDelegate: AnyObject {
    func dismissed()
}

class MrzHelpViewController: UIViewController {

    @IBOutlet weak var mrzImageView: UIImageView!

    weak var delegate: MrzHelpViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        let imageInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 0)
        mrzImageView.image = UIImage(named: "mrz_reader_helper")?.withAlignmentRectInsets(imageInsets)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func onTap(gesture: UITapGestureRecognizer) {
        navigationController?.popViewController(animated: true)
        delegate?.dismissed()
    }

}

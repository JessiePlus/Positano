//
//  BaseInputMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/9/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class BaseInputMailViewController: BaseViewController {

    @IBOutlet weak var mailAddressTextField: BorderTextField!
    @IBOutlet weak var mailAddressTextFieldTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var passwordTextField: BorderTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mailAddressTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
    }

    func tappedKeyboardReturn() {
        assert(false, "Must override tappedKeyboardReturn")
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        guard let address = mailAddressTextField.text, !address.isEmpty else { return true }
        
        tappedKeyboardReturn()
        
        return true
    }
}


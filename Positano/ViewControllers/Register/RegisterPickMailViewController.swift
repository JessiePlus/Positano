//
//  RegisterPickMailViewController.swift
//  Positano
//
//  Created by dinglin on 2016/12/10.
//  Copyright © 2016年 dinglin. All rights reserved.
//

import UIKit
import PositanoKit
import Ruler
import RxSwift
import RxCocoa

final class RegisterPickMailViewController: BaseInputMailViewController, UITextFieldDelegate {
    
    fileprivate lazy var disposeBag = DisposeBag()
    
    @IBOutlet weak var pickMailAddressPromptLabel: UILabel!
    
    @IBOutlet weak var pickMailAddressPromptLabelTopConstraint: NSLayoutConstraint!
    
    
    fileprivate lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.title = String.trans_buttonNextStep
        button.rx.tap
            .subscribe(onNext: { [weak self] in self?.tryShowRegisterVerifyMobile() })
            .addDisposableTo(self.disposeBag)
        return button
    }()
    
    deinit {
        println("deinit RegisterPickMail")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.yepViewBackgroundColor()
        
        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Sign Up", comment: ""))
        
        navigationItem.rightBarButtonItem = nextButton
        
        pickMailAddressPromptLabel.text = NSLocalizedString("What's your e-mail?", comment: "")
        
        let mailAddress = sharedStore().state.mailAddress
        
        //mobileNumberTextField.placeholder = ""
        mailAddressTextField.text = mailAddress?.address
        mailAddressTextField.backgroundColor = UIColor.white
        mailAddressTextField.textColor = UIColor.yepInputTextColor()
        mailAddressTextField.delegate = self
        
        Observable.combineLatest(mailAddressTextField.rx.textInput.text, mailAddressTextField.rx.textInput.text) { (a, b) -> Bool in
            guard let b = b else { return false }
            return !b.isEmpty
            }
            .bindTo(nextButton.rx.isEnabled)
            .addDisposableTo(disposeBag)
        
        
        
        pickMailAddressPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        
        if mailAddress?.address == nil {
            nextButton.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mailAddressTextField.becomeFirstResponder()
    }
    
    // MARK: Actions
    
    override func tappedKeyboardReturn() {
        tryShowRegisterVerifyMobile()
    }
    
    func tryShowRegisterVerifyMobile() {
        
        view.endEditing(true)
        
        guard let address = mailAddressTextField.text else {
            return
        }
        let mailAddress = MailAddress(address: address)
        sharedStore().dispatch(MailAddressUpdateAction(mailAddress: mailAddress))
        
        YepHUD.showActivityIndicator()
        
        validateMailAddress(mailAddress, failureHandler: { (reason, errorMessage) in
            
            YepHUD.hideActivityIndicator()
            
        }, completion: { (available, message) in
            
            if available, let nickname = PositanoUserDefaults.nickname.value {
                println("ValidateMobile: available")
                
                registerMailAddress(mailAddress, nickname: nickname, failureHandler: { (reason, errorMessage) in
                    
                    YepHUD.hideActivityIndicator()
                    
                    if let errorMessage = errorMessage {
                        YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: { [weak self] in
                            self?.mailAddressTextField.becomeFirstResponder()
                        })
                    }
                    
                }, completion: { created in
                    
                    YepHUD.hideActivityIndicator()
                    
                    if created {
                        SafeDispatch.async { [weak self] in
                            self?.performSegue(withIdentifier: "showRegisterVerifyMobile", sender: nil)
                        }
                        
                    } else {
                        SafeDispatch.async { [weak self] in
                            self?.nextButton.isEnabled = false
                            
                            YepAlert.alertSorry(message: "registerMobile failed", inViewController: self, withDismissAction: { [weak self] in
                                self?.mailAddressTextField.becomeFirstResponder()
                            })
                        }
                    }
                })
                
            } else {
                println("ValidateMobile: \(message)")
                
                YepHUD.hideActivityIndicator()
                
                SafeDispatch.async { [weak self] in
                    self?.nextButton.isEnabled = false
                    
                    YepAlert.alertSorry(message: message, inViewController: self, withDismissAction: { [weak self] in
                        self?.mailAddressTextField.becomeFirstResponder()
                    })
                }
            }
        })
    }
}

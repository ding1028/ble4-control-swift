//
//  PasswordInitViewController.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/9/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import Localize_Swift

class PasswordInitViewController: UIViewController {
    var completionHandler : ((_ password: String, _ action:String) -> Void)?
    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnConfirm: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func configureUI() {
        lblTitle.text = "enter_password".localized();
        btnConfirm.setTitle("confirm".localized(), for: .normal);
        btnConfirm.setTitle("cancel".localized(), for: .normal);
        txtPassword.becomeFirstResponder();
    }
    
    func validateInput() -> Bool{
        if(txtPassword.text!.count != 6) {
            AlertHelper.shared.alert(title: "whoops".localized(), message: "short_password".localized(), vc: self)
            return false;
        }
        return true;
        
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        if(!validateInput()) {
            return;
        }
        dismiss(animated: true) {
            self.completionHandler?(self.txtPassword.text!, "confirm");
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true) {
            self.completionHandler?(self.txtPassword.text!, "cancel");
        }
    }
    

}

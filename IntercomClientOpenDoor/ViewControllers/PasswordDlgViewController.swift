//
//  PasswordDlgViewController.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/9/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import Localize_Swift

class PasswordDlgViewController: UIViewController, UITextFieldDelegate {
    var completionHandler : ((_ password: String, _ action:String) -> Void)?
    @IBOutlet weak var lblConfirmPassword: UILabel!
    @IBOutlet weak var lblOldPassword: UILabel!
    @IBOutlet weak var txtOldPassword: UITextField!
    @IBOutlet weak var lblNewPassword: UILabel!
    @IBOutlet weak var txtNewPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    var oldPassword = "";
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI();
    }
    func configureUI() {
        lblOldPassword.text = "enter_old_password".localized();
        lblNewPassword.text = "enter_new_password".localized();
        lblConfirmPassword.text =
            "enter_confirm_password".localized();
        btnConfirm.setTitle("confirm".localized(), for: .normal);
        btnCancel.setTitle("cancel".localized(), for: .normal);
        
        txtOldPassword.becomeFirstResponder();
        txtOldPassword.delegate = self;
        txtNewPassword.delegate = self;
        txtConfirmPassword.delegate = self;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if (textField == self.txtOldPassword) {
            self.txtNewPassword.becomeFirstResponder()
        }
        return true
    }
    
    func validateInput() -> Bool {
        if(self.txtNewPassword.text!.count != 6) {
            AlertHelper.shared.alert(title: "whoops".localized(), message: "short_password".localized(), vc: self)
            return false;
        }
        if(self.txtOldPassword.text! != self.oldPassword) {
            print("old password:", self.oldPassword);
            print("entered old password:", self.txtOldPassword.text!);
            AlertHelper.shared.alert(title: "whoops".localized(), message: "invalid_old_password".localized(), vc: self)
            return false;
        }
        if(self.txtNewPassword.text! != self.txtConfirmPassword.text!) {
            AlertHelper.shared.alert(title: "whoops".localized(), message: "confirm_password_incorrect".localized(), vc: self)
            return false;
        }
        return true;
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.txtOldPassword.resignFirstResponder();
            self.txtNewPassword.resignFirstResponder();
            self.txtConfirmPassword.resignFirstResponder();
        }
        super.touchesBegan(touches, with: event)
    }
    @IBAction func actionConfirm(_ sender: Any) {
        if(!validateInput()) {
            return;
        }
        dismiss(animated: true) {
            self.completionHandler?(self.txtNewPassword.text ?? self.oldPassword, "confirm");
        }
    }
    @IBAction func actionCancel(_ sender: Any) {
        dismiss(animated: true) {
            self.completionHandler?(self.oldPassword, "cancel");
        }
    }
    
    
}

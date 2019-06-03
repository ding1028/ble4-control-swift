//
//  NameDlgViewController.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/9/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import Localize_Swift

class MenuDlgViewController: UIViewController {
    var completionHandler : ((_ name: String, _ action:String) -> Void)?
    var defaultChangeHandler : ((_ isDefault: Bool) -> Void)?
    @IBOutlet weak var btnChangePass: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnConfirm: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnDefault: UIButton!
    var isDefault = false
    var defaultName = "";

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureUI();
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        // dismiss(animated: true, completion: nil)
    }

    func configureUI() {
        lblTitle.text = "enter_name".localized()
        txtName.text = defaultName;
        btnConfirm.setTitle("confirm".localized(), for: .normal);
        btnCancel.setTitle("cancel".localized(), for: .normal);
        btnChangePass.setTitle("change_password".localized(), for: .normal)
        btnDelete.setTitle("delete".localized(), for: .normal);
        
        if(isDefault) {
            btnDefault.setTitle("cancel_default".localized(), for: .normal);
        }else {
            btnDefault.setTitle("make_default".localized(), for: .normal);
        }
        
    
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        dismiss(animated: true) {
            self.defaultName = self.txtName.text ?? self.defaultName;
            self.completionHandler?(self.defaultName, "confirm");
            
        }
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true) {
            self.defaultName = self.txtName.text ?? self.defaultName;
            self.completionHandler?(self.defaultName, "cancel");
            
        }
    }
    @IBAction func makeDefault(_ sender: Any) {

        dismiss(animated: true) {
            self.isDefault = !self.isDefault
            self.defaultChangeHandler?(self.isDefault)
        }
    }
    @IBAction func deleteAction(_ sender: Any) {
         dismiss(animated: true) {
        self.completionHandler?(self.defaultName, "delete");
        }
    }
    
    @IBAction func changePassword(_ sender: Any) {
         dismiss(animated: true) {
        self.completionHandler?(self.defaultName, "change_password");
              }
    }
}

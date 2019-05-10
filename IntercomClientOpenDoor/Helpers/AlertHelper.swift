//
//  AlertHelper.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/9/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit

class AlertHelper: NSObject {
    static let shared = AlertHelper()
    func alert(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        vc.present(alert, animated: true)
    }
}

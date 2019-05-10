//
//  GateTableViewCell.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/9/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit

class GateTableViewCell: UITableViewCell {

    @IBOutlet weak var doorOpenFirst: UIButton!
    @IBOutlet weak var doorOpenSecond: UIButton!
    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var maskImage: UIButton!
    
    var actionOpenDoorFirst: (() -> Void)? = nil
    var actionOpenDoorSecond: (() -> Void)? = nil
    var actionReconnect: (() -> Void)? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func doorOpenAction(_ sender: Any) {
        if let doorOpen = actionOpenDoorFirst {
            doorOpen();
        }

    }
    @IBAction func doorOpen2Action(_ sender: Any) {
        if let doorOpen = actionOpenDoorSecond {
            doorOpen();
        }
    }
    @IBAction func reconnectAction(_ sender: Any) {
        if let reconnect = actionReconnect {
            reconnect();
        }
    }
    
}

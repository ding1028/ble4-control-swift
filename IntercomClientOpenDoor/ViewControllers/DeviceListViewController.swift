//
//  DeviceListViewController.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/8/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import CoreBluetooth
import Localize_Swift

class DeviceListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate  {

    var UUID_NOTIFY  = "FFE1";
    var UUID_SERVICE = "FFE0";
    var peripherals:[CBPeripheral] = [];
    var manager:CBCentralManager? = nil
    var parentView:MainViewController? = nil
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stateShowLabel: UILabel!

    @IBOutlet weak var scanForDevices: UIView!
    
    @IBOutlet weak var btnScan: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI();
        scanPeripherals();
        

    }
    
    //configure ui for translation and custom ui changes
    func configureUI(){
        containerView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 0.6).cgColor;
        containerView.layer.cornerRadius = 8;
        progressIndicator.hidesWhenStopped = true;
        
        tableView.delegate = self
        tableView.dataSource = self
        scanForDevices.isHidden = true;
        btnScan.setTitle("scan_for_devices".localized(), for: .normal);
    }
    
    //dismiss action when touch on rest area of content box
    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func scanAction(_ sender: Any) {
        scanPeripherals();
    }
    
    //scan peripherals
    func scanPeripherals(){
        print("scan peripherals")
        let serviceUUIDs:[CBUUID] = [CBUUID(string: UUID_SERVICE)]
        manager?.scanForPeripherals(withServices: nil, options: nil)
        self.progressIndicator.startAnimating();
    self.stateShowLabel.text="scanning_for_devices".localized();
        self.scanForDevices.isHidden = true;
        //stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.stopScan()
        }
     
    }
    
    //stop scan
    func stopScan() {
        manager?.stopScan()
        self.stateShowLabel.text="select_device".localized();
        self.progressIndicator.stopAnimating();
        self.scanForDevices.isHidden = false;
    }
    
    //connect peripheral
    func connectPeripheral(withPeripheral peripheral:CBPeripheral) {
        print("connect", peripheral);
        manager?.connect(peripheral, options: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :PeripheralTableViewCell = tableView.dequeueReusableCell(withIdentifier: "scanTableCell", for: indexPath as IndexPath) as! PeripheralTableViewCell
        let peripheral = peripherals[indexPath.row]
        cell.name?.text = peripheral.name ?? "Unnamed"
        
        return cell
    }
    
    //once click on item, connect to selected peripheral and cancel discovery then dismiss this devicelist screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = peripherals[indexPath.row];
        
        connectPeripheral(withPeripheral: peripheral);
        stopScan();
        dismiss(animated: true, completion: nil);
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 40;//Choose your custom row height
    }
    
    
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(!peripherals.contains(peripheral) && peripheral.name?.contains("Bee-BLE") ?? false) {
            peripherals.append(peripheral)
        }
        
        self.tableView.reloadData()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        //pass reference to connected peripheral to parent view
        let serviceUUIDs:[CBUUID] = [CBUUID(string: UUID_SERVICE)]
        parentView?.mainPeripheral = peripheral
        peripheral.delegate = parentView as! CBPeripheralDelegate
        peripheral.discoverServices(nil)
        
        //set the manager's delegate view to parent so it can call relevant disconnect methods
        manager?.delegate = parentView;
        dismiss(animated: true, completion: nil)
        
        print("Connected to " +  peripheral.name!)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error!)
    }
    

}

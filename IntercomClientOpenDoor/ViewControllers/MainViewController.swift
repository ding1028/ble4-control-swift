//
//  ViewController.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/8/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import Localize_Swift
import CoreBluetooth

class MainViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var msgDoorOpen: UIView!
    @IBOutlet weak var btnSetBig: UIButton!
    @IBOutlet weak var btnFind: UIButton!
    @IBOutlet weak var lblOpenDoor: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblGateName: UILabel!
    var CMD_BOARD_TYPE = 0;
    var CMD_CHECK_PWD = 1;
    var CMD_CHANGE_PWD = 2;
    var CMD_QUERY_MODE = 3;
    var CMD_QUERY_STATUS = 4;
    var CMD_NO_REPLY = 5;
    var CMD_OPEN_DOOR = 6;
    var CMD_OPEN_DOOR_2 = 7;
    var CMD_CLOSE_DOOR = 8;
    var CMD_CLOSE_DOOR_2 = 9;
    var UUID_NOTIFY  = "FFE1";
    var UUID_SERVICE = "FFE0";
    var BORAD_TYPE_REQUEST = "3C";

    
    
    var gateArrayList:[Gate] = [];
    var mainPeripheral:CBPeripheral? = nil;
    var mainCharacteristic:CBCharacteristic? = nil
    

    var mainGate:Gate? = nil;
    
    var manager:CBCentralManager? = nil
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureUI()
        
        manager = CBCentralManager(delegate: self, queue: nil);
        self.loadGates();
        self.showSpinner(onView: self.view)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.refreshLoadedGates();
            self.removeSpinner()
        })
        

    
    
    }

    
    func configureUI() {
        btnFind.setTitle("find".localized(), for: .normal)
        btnSetBig.setTitle("no_devices_press_to_find".localized(), for: .normal)
        
        lblOpenDoor.text = "open_door".localized()
        tableView.delegate = self
        tableView.dataSource = self
        
         self.msgDoorOpen.isHidden = true;
        
    }
    
    func updateUI() {
        if(gateArrayList.count > 0) {
            btnSetBig.isHidden = true;
        }
        if let gate = mainGate {
            lblGateName.text = gate.name;
        }
        tableView.reloadData();
        saveGates();
    }
    

    @IBAction func actionFindDevice(_ sender: Any) {
        openFindDevices();
    }
    @IBAction func actionSmallFindDevice(_ sender: Any) {
        openFindDevices();
    }
    
    func openFindDevices() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scanController: DeviceListViewController = storyboard.instantiateViewController(withIdentifier: "DeviceListViewController") as! DeviceListViewController
        
        scanController.modalPresentationStyle = .overCurrentContext;
        manager?.delegate = scanController;
        scanController.manager = manager;
        scanController.parentView = self;
        
        self.present(scanController, animated: true, completion: nil)
    }

    func deleteGate(gate: Gate) {
        var indexToDelete = -1;
        for(index, item) in gateArrayList.enumerated() {
            if(item.identifier == gate.identifier) {
                
                indexToDelete = index;
            }
        }
        if(indexToDelete >= 0) {
            gateArrayList.remove(at: indexToDelete);
        }
        saveGates();
        
    }
    
    func addGate(peripheral: CBPeripheral, characteristic: CBCharacteristic, name: String?) {

        var isExist = false;
        //check gate exist already
        for(_, item) in gateArrayList.enumerated() {
            if(item.identifier == peripheral.identifier) {
                isExist = true;
                item.peripheral = peripheral;
                item.characteristic = characteristic;
                item.isAvailable = true;
                mainGate = item;
            }
        }
        if(!isExist) {
            let gate = Gate();
            gate.identifier = peripheral.identifier;
            gate.isAvailable = true;
            gate.isVerify = false;
            gate.name = name ?? peripheral.name ?? "undefined";
            gate.peripheral = peripheral;
            gate.characteristic = characteristic;
            gateArrayList.append(gate);
            mainGate = gate;
            gate.writeCommand(commandType: self.CMD_BOARD_TYPE);
        }
        tableView.reloadData();
        updateUI();
    }
    
    func saveGates() {
        LocalData.shared.setBluetoothObjects(gateArr: gateArrayList);
    }
    
    func loadGates() {
        gateArrayList =  LocalData.shared.getBluetoothObjects();
        updateUI();
    }
    func refreshLoadedGates(){
        var identifiers: [UUID] = [];
        for(_, item) in gateArrayList.enumerated() {
            if let identifier = item.identifier {
                identifiers.append(identifier);
            }
        }
        if let peripherals: [CBPeripheral] = manager?.retrievePeripherals(withIdentifiers: identifiers) {
            for(_, peripheral) in peripherals.enumerated() {
                if let gate: Gate = getGateById(identifier: peripheral.identifier) {
                    gate.peripheral = peripheral;
                    print("retrived peripheral connect:", peripheral.name ?? "UnNamed");
                    manager?.connect(peripheral, options: nil);
                }
            }
        }
        updateUI();
    }

    func notifyCallback(charac : CBCharacteristic) {
        
        let peripheral = charac.service.peripheral;
        let identifier = peripheral.identifier;
        if let gate = getGateById(identifier: identifier) {
            if let data = charac.value {
                let responseStr = data.hexEncodedString();
                print("response:", responseStr);
                if(gate.cmdType == CMD_BOARD_TYPE) {
                    
                    if(responseStr.hasSuffix("1")) {
                        //with Password
                        gate.isPasswordMode = true;
                        if( gate.password != nil ) {
                            gate.sendCheckPassword(password: gate.password!);
                        } else {
                            showEnterPasswordDlg(gate: gate);
                        }
                   
                    } else {
                        gate.isPasswordMode = false;
                        gate.isVerify = true;
                    }
                } else if (gate.cmdType == CMD_CHECK_PWD) {
                    if("01" == responseStr) {
                        print("Password verified.")
                        gate.isVerify = true;
                    }else {
                        print("Invalid Password.")
                        AlertHelper.shared.alert(title: "whoops".localized(), message: "password_invalid".localized(), vc: self);
                        gate.isVerify = false;
                        self.showEnterPasswordDlg(gate: gate)
                    }
                } else if (gate.cmdType == CMD_CHANGE_PWD) {
                    if("01" == responseStr) {
                        print("Password changed.")
                    } else  {
                        print("Password change faild.")
                    }
                }
                
            }
        }
        

    }
    
    func openNameDlg(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        
        let defaultName = peripheral.name ?? "UnNamed";
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let nameDlgController: NameDlgViewController = storyboard.instantiateViewController(withIdentifier: "NameDlgViewController") as! NameDlgViewController;
        nameDlgController.modalPresentationStyle = .overCurrentContext;
        nameDlgController.defaultName = defaultName;
        
        let completionHandler:(_ name: String, _ action:String)->Void = { (name, action) in
            self.addGate(peripheral: peripheral, characteristic: characteristic,  name: name);
            
        }
        nameDlgController.completionHandler = completionHandler;
        self.present(nameDlgController, animated: true, completion: nil)
        
    }
    
    func showEditPasswordDlg(oldPassword: String, gate: Gate){
        if(!gate.isVerify) {
            self.showEnterPasswordDlg(gate: gate);
            return;
        }
        print("show edit passsword dialog");
        print("old passowrd:", oldPassword);
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let editDlgController: PasswordDlgViewController = storyboard.instantiateViewController(withIdentifier: "PasswordDlgViewController") as! PasswordDlgViewController;
        editDlgController.modalPresentationStyle = .overCurrentContext;
        editDlgController.oldPassword = oldPassword;
        let completionHandler:(_ password: String, _ action:String)->Void = { (password, action) in
                print("password:", password );
                if(action == "confirm") {
                    //send change password command
                    gate.password = password;
                    gate.sendChangePassword(password: password);
                }
            

        }
        editDlgController.completionHandler = completionHandler;
 
        self.present(editDlgController, animated: true, completion: nil);
    }
    func showEnterPasswordDlg(gate: Gate) {

        print("show enter passsword dialog");
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let enterDlgController: PasswordInitViewController = storyboard.instantiateViewController(withIdentifier: "PasswordInitViewController") as! PasswordInitViewController;
        enterDlgController.modalPresentationStyle = .overCurrentContext;
        let completionHandler:(_ password: String, _ action:String)->Void = { (password, action) in
                print("password:", password );
                if(action == "confirm") {
                    //send change password command
                    gate.password=password;
                    print("check password:", password);
                    gate.sendCheckPassword(password: password)
               
                  
                }
            
        }
        enterDlgController.completionHandler = completionHandler;
         self.present(enterDlgController, animated: true, completion: nil);
    }
    
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let gate = getGateById(identifier: peripheral.identifier) {
            gate.isAvailable = false;
            updateUI();
        }
        
        
        print("Disconnected" + peripheral.name!)
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        //pass reference to connected peripheral to parent view
        peripheral.discoverServices(nil)
        peripheral.delegate = self;
        //set the manager's delegate view to parent so it can call relevant disconnect methods
        print("Connected to " +  peripheral.name!)
    }
    // MARK: CBPeripheralDelegate Methods
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            print("Service found with UUID: " + service.uuid.uuidString)
            if (service.uuid.uuidString == UUID_SERVICE) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if (service.uuid.uuidString == UUID_SERVICE) {
            
            for characteristic in service.characteristics! {
                
                if (characteristic.uuid.uuidString == UUID_NOTIFY) {
                    
                    //Set Notify is useful to read incoming data async
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Found Data Characteristic")
                    if let gate = getGateById(identifier: peripheral.identifier) {
                        gate.peripheral = peripheral;
                        gate.characteristic = characteristic;
                        gate.isAvailable = true;
                        self.updateUI();
                        return;
                    }
                    
                    //add gate
                    self.openNameDlg(peripheral: peripheral, characteristic: characteristic);
                   
                }
                
            }
            
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if ((error) != nil) {
            print("updateValueForCharacteristic failed");
            return;
        }
        
        if (characteristic.uuid.uuidString == UUID_NOTIFY) {
            //data recieved
            if(characteristic.value != nil) {
                notifyCallback(charac: characteristic);
            }
        }
    }
    //#Mark tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gateArrayList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :GateTableViewCell = tableView.dequeueReusableCell(withIdentifier: "GateTableViewCell", for: indexPath as IndexPath) as! GateTableViewCell
        let gate = gateArrayList[indexPath.row]
        cell.nameLabel.text = gate.name;
        cell.tag = indexPath.row;
        let longPressGest = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(sender:)))
        longPressGest.minimumPressDuration = 1.0
        cell.addGestureRecognizer(longPressGest)
        
        cell.actionOpenDoorFirst = {
            self.openDoorFirst(gate: gate);
        }
        cell.actionOpenDoorSecond = {
            self.openDoorSecond(gate: gate);
        }
        cell.actionReconnect = {
            self.reconnectGate(gate: gate);
        }
        if(gate.isAvailableGate()) {
            cell.maskImage.isHidden = true;
        } else {
            cell.maskImage.isHidden = false;
        }
        return cell
    }
    
    //once click on item, connect to selected peripheral and cancel discovery then dismiss this devicelist screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let gate = gateArrayList[indexPath.row];

    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 84;//Choose your custom row height
    }
    
    
    //#Mark Long press action
    
    @objc func longPress(sender: UITapGestureRecognizer) {
        if (sender.state == .ended) {
            if let tag = sender.view?.tag {
                let gate = gateArrayList[tag];
                mainGate = gate;
                let defaultName = gate.name;
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil);
                let menuDlgController: MenuDlgViewController = storyboard.instantiateViewController(withIdentifier: "MenuDlgViewController") as! MenuDlgViewController;
                menuDlgController.modalPresentationStyle = .overCurrentContext;
                menuDlgController.defaultName = defaultName;
                
                let completionHandler:(_ name: String, _ action:String)->Void = { (name, action) in
                    gate.name = name;
                    if(action == "delete") {
                        self.deleteGate(gate: gate)
                    } else if (action == "change_password") {
                        guard let password = gate.password else {
                            self.showEnterPasswordDlg(gate: gate);
                            self.updateUI();
                            return;
                        }
                        self.showEditPasswordDlg(oldPassword: password, gate: gate)
                    }
                    self.updateUI();
                }
                menuDlgController.completionHandler = completionHandler;
                self.present(menuDlgController, animated: true, completion: nil)
                
            }
        }
    }
    
    func openDoorFirst(gate: Gate) {
        if(gate.isDoorOneOpening) {
            return;
        }
        mainGate = gate;
        if(!gate.isAvailableGate()) {
            return;
        }
        if(gate.isVerify) {
            
            gate.sendCheckPassword(password: gate.password ?? "123456");
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                gate.isDoorOneOpening = true;
                self.playDoorOpenSound();
                gate.writeCommand(commandType: self.CMD_OPEN_DOOR)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                    gate.isDoorOneOpening = false;
                    gate.writeCommand(commandType: self.CMD_CLOSE_DOOR);
                    self.playDoorCloseSound();
                })
                return;
            })

        } else {
            //gate.writeCommand(commandType: CMD_BOARD_TYPE)
            showEnterPasswordDlg(gate: gate);
            
        }
        updateUI();
    }
    
    
    
    func openDoorSecond(gate: Gate) {
        if(gate.isDoorTwoOpening) {
            return;
        }
   
        mainGate = gate;
        if(!gate.isAvailableGate()) {
            return;
        }
        if(gate.isVerify) {
            gate.sendCheckPassword(password: gate.password ?? "123456");
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.playDoorOpenSound();
                gate.isDoorTwoOpening = true;
                gate.writeCommand(commandType: self.CMD_OPEN_DOOR_2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                     gate.isDoorTwoOpening = false;
                    gate.writeCommand(commandType: self.CMD_CLOSE_DOOR_2);
                    self.playDoorCloseSound();
                })
                return;
            })
           
        } else {
            //gate.writeCommand(commandType: CMD_BOARD_TYPE)
            showEnterPasswordDlg(gate: gate);
            
        }
        updateUI();
    }
    
    func reconnectGate(gate: Gate) {
        print("reconnectGate");
        guard let peripheral = gate.peripheral  else {
            return;
        }
        manager?.connect(peripheral, options: nil)
    }
    func connectToGate(gate: Gate) -> Bool{
        if(mainGate?.identifier == gate.identifier) {
            
        }
        
        return true;
    }
    
    func getGateById(identifier: UUID) -> Gate? {
        for(_, item) in gateArrayList.enumerated() {
            if(item.identifier == identifier) {
                return item;
            }
        }
        return nil;
    }
    
    func playDoorOpenSound() {
        print("open door sound play");
        RingPlayer.shared.playDoorOpen();
        self.msgDoorOpen.isHidden = false;
        
    }
    
    func playDoorCloseSound() {
        print("close door sound");
        RingPlayer.shared.playDoorClose();
        self.msgDoorOpen.isHidden = true;
    }
    
}

var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

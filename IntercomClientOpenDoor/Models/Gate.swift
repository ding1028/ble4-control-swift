//
//  Gate.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/8/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit
import CoreBluetooth

class Gate: NSObject, NSCoding {
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
    
    var cmdType = -1;
    var name:String = "";
    var isAvailable:Bool = false;
    var isPasswordMode: Bool = true;
    var password:String?;
    var newPassword:String?;
    var availableTimestamp = 0;
    var identifier:UUID?;
    var isVerify = false;
    var peripheral:CBPeripheral? = nil;
    var characteristic:CBCharacteristic? = nil
    
    var isDoorOneOpening:Bool = false;
    var isDoorTwoOpening: Bool = false;
    
    func write(command: String) {
        let data = hexStringToData(command);
        print("encoded command", data);
        if(characteristic!.properties.contains(CBCharacteristicProperties.writeWithoutResponse)) {
            peripheral?.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }else {
            peripheral?.writeValue(data, for: characteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func writeCommand(commandType: Int) {
        if(!isAvailable) {
            return;
        }
        cmdType = commandType;
        let command: String = self.getCommandForCommandType(commandType: commandType);
        print("sending command:", command);
        write(command: command);

    }
    
    func sendChangePassword(password: String) {
        self.password = password;
        if(!isAvailable) {
            return;
        }
        cmdType = CMD_CHANGE_PWD;
        let command = "40" + toHex(arg: password) ;
        print("hex password change sending:", command);
        write(command: command);
    }
    func sendCheckPassword(password: String) {
        print("check password:", password)
        if(!isAvailable) {
            return;
        }
        cmdType = CMD_CHECK_PWD;
        let command = "3F" + toHex(arg: password) ;
         print("hex password check sending:", command);
        write(command: command);
    }
    
    func toHex(arg: String) -> String {
        let hexString = String(format:"%06X", Int(arg)!)
        print("hexLong", hexString);
        var pwdHex2 = "";
        
        
        for i in 0...2 {
            let range = i * 2..<(i+1)*2
            pwdHex2 = hexString.substring(with: range) + pwdHex2;
        }
        return pwdHex2;
    }
    func hexStringToData(_ string: String) -> Data {
        let byteArr :[UInt8] = stringToBytes(string) ?? [];
        let data = Data(bytes: byteArr, count: byteArr.count);
        return data;
    }
    
    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    
    func isAvailableGate() -> Bool {
        return isAvailable;
    }
    func getCommandForCommandType( commandType: Int) -> String {
        switch commandType {
        case CMD_BOARD_TYPE:
            return "3C";
        case CMD_QUERY_MODE:
            return "43";
        case CMD_OPEN_DOOR:
            return "65";
        case CMD_OPEN_DOOR_2:
            return "66";
        case CMD_CLOSE_DOOR:
            return "6F";
        case CMD_CLOSE_DOOR_2:
            return "70";
        default:
            return "3C";
        }
    }
    
    override init() {
        
    }
    init(gateName: String, gateIdentifier: UUID, gatePassword: String?, gateIsPasswordMode: Bool, gateIsVerify: Bool) {
        name = gateName;
        identifier = gateIdentifier;
        password = gatePassword;
        isPasswordMode = gateIsPasswordMode;
        isVerify = gateIsVerify;
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let identifier = aDecoder.decodeObject(forKey: "identifier") as! UUID
        let password = aDecoder.decodeObject(forKey: "password") as? String
        let isPasswordMode = aDecoder.decodeObject(forKey: "ispasswordmode") as? Bool
        let isVerify = aDecoder.decodeObject(forKey: "isverify") as? Bool
        self.init(gateName: name, gateIdentifier: identifier, gatePassword: password, gateIsPasswordMode: isPasswordMode ?? true, gateIsVerify: isVerify ?? false);
    }
    
    func encode(with aCoder: NSCoder){
        
        aCoder.encode(name, forKey: "name")
        aCoder.encode(identifier, forKey: "identifier")

        aCoder.encode(isPasswordMode, forKey: "ispasswordmode")
        aCoder.encode(isVerify, forKey: "isverify")
        if let p = password {
            aCoder.encode(p, forKey: "password")
        }
    }
    
    
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return substring(to: toIndex)
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return substring(with: startIndex..<endIndex)
    }
}

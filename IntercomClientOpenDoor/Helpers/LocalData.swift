//
//  LocalData.swift
//  IntercomClientOpenDoor
//
//  Created by my on 5/8/19.
//  Copyright © 2019 newlinks. All rights reserved.
//

import UIKit

class LocalData: NSObject {
    static let shared = LocalData()
    private override init() {
    }
    
    func getDefautGate() -> UUID? {
        return UserDefaults.standard.object(forKey: "defaultGate") as? UUID;
    }
    func setDefaultGate(identifier: UUID?) {
        if let identifier = identifier {
            UserDefaults.standard.set(identifier, forKey: "defaultGate")
        }
    }
    func cancelDefaultGate(){
        UserDefaults.standard.removeObject(forKey: "defaultGate")
    }
    
    func getBluetoothObjects() -> [Gate] {
        let gatesData = UserDefaults.standard.object(forKey: "gateArrayList") as? NSData
        
        if let gatesData = gatesData {
            let gatesArray = NSKeyedUnarchiver.unarchiveObject(with: gatesData as Data) as? [Gate]
            
            if let gatesArray = gatesArray {
                return gatesArray;
            }
            
        }
        return [];
    }
    
    func addBluetoothObject(gate: Gate) {
        var gateArrayList: [Gate] = getBluetoothObjects();
        var added = false;
        
        for (_, gate) in gateArrayList.enumerated() {
            if(gate.identifier == gate.identifier) {
                added = true;
                break;
            }
        }
        if(!added) {
            gateArrayList.append(gate);
        }
        setBluetoothObjects(gateArr: gateArrayList);
    }
    
    func setBluetoothObjects(gateArr: [Gate]) {
        do {
            let gateArrayList = try NSKeyedArchiver.archivedData(withRootObject: gateArr, requiringSecureCoding: false)
            UserDefaults.standard.set(gateArrayList, forKey: "gateArrayList")
        }
        catch {
            print("error on save data");
        }
    
    
    }
    
    func removeBluetoothObject(gate: Gate) {
        var gateArrayList: [Gate] = getBluetoothObjects();
        var indexToRemove = -1;
        for (index , gate) in gateArrayList.enumerated() {
            if(gate.identifier == gate.identifier) {
                indexToRemove = index;
                break;
            }
        }
        
        if(indexToRemove > 0) {
            gateArrayList.remove(at: indexToRemove);
        }
        setBluetoothObjects(gateArr: gateArrayList);
    }
}

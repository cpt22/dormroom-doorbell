//
//  Doorbell.swift
//  Lampi
//
//  Created by Christian Tingle on 4/13/21.
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

class Doorbell: Device {
    var state = State() {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    private var associationCodeCharacteristic: CBCharacteristic?
    private var associationStateCharacteristic: CBCharacteristic?
    
    override init(name: String) {
        super.init(name: name)
    }
    override init(devicePeripheral: CBPeripheral) {
        super.init(devicePeripheral: devicePeripheral)
    }
    
    override func isConnected() -> Bool {
        return super.isConnected() && self.associationCodeCharacteristic != nil && self.associationStateCharacteristic != nil
    }
    
    override func refresh() {
        if (devicePeripheral != nil) {
            if (self.associationStateCharacteristic != nil) {
                devicePeripheral!.readValue(for: self.associationStateCharacteristic!)
            }
            if (self.associationCodeCharacteristic != nil) {
                devicePeripheral!.readValue(for: self.associationCodeCharacteristic!)
            }
        }
    }
}

extension Doorbell {
    static let DOORBELL_SERVICE_UUID = CBUUID(string: "9770695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_CODE_UUID = CBUUID(string: "9771695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_STATE_UUID = CBUUID(string: "9772695f-2ca0-4144-af5d-90a86d82ab40")
}

extension Doorbell {
    struct State: Equatable {
        var isAssociated = false
        var associationCode = ""
    }
}

extension Doorbell {
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        super.peripheral(peripheral, didDiscoverServices: error)
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Found: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        super.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
                case Doorbell.ASSOC_STATE_UUID:
                    self.associationStateCharacteristic = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
            
                case Doorbell.ASSOC_CODE_UUID:
                    self.associationCodeCharacteristic = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                default:
                    continue
            }
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        super.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
        
        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }
        
        switch characteristic.uuid {
            case Doorbell.ASSOC_STATE_UUID:
                state.isAssociated = parseBoolean(for: updatedValue)
                
            case Doorbell.ASSOC_CODE_UUID:
                state.associationCode = parseString(for: updatedValue)
                
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

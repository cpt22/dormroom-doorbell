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
    @Published var state = State()
    
    private var ssidCharacteristic: CBCharacteristic?
    private var pskCharacteristic: CBCharacteristic?
    private var wifiUpdateCharacteristic: CBCharacteristic?
    
    private var associationCodeCharacteristic: CBCharacteristic?
    private var associationStateCharacteristic: CBCharacteristic?
    
    override init(name: String) {
        super.init(name: name)
    }
    override init(devicePeripheral: CBPeripheral) {
        super.init(devicePeripheral: devicePeripheral)
    }
}

extension Doorbell {
    static let DOORBELL_SERVICE_UUID = CBUUID(string: "9770695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_CODE_UUID = CBUUID(string: "9771695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_STATE_UUID = CBUUID(string: "9772695f-2ca0-4144-af5d-90a86d82ab40")
    
    private func sendWifiConfiguration(force: Bool = false) {
        print("hit method")
        if isConnected {//&& (force || !shouldSkipUpdateDevice) {
            pendingBluetoothUpdate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                print("hit async")
                self?.writeSSID()
                self?.writePSK()
                self?.writeUpdate()
                
                self?.pendingBluetoothUpdate = false
            }
        }
    }
    
    private func writeSSID() {
        print("Trying ssid")
        if let ssidCharacteristic = ssidCharacteristic {
            print("found ssid")
            let valueString = (state.ssid as NSString).data(using: String.Encoding.utf8.rawValue)
            print(valueString)
            devicePeripheral?.writeValue(valueString!, for: ssidCharacteristic, type: .withResponse)
        }
    }
    
    private func writePSK() {
        if let pskCharacteristic = pskCharacteristic {
            let valueString = (state.psk as NSString).data(using: String.Encoding.utf8.rawValue)
            print(valueString)
            devicePeripheral?.writeValue(valueString!, for: pskCharacteristic, type: .withResponse)
        }
    }
    
    private func writeUpdate() {
        if let wifiUpdateCharacteristic = wifiUpdateCharacteristic {
            var val: UInt8 = 1
            let data = Data(bytes: &val, count: 1)
            print(data)
            devicePeripheral?.writeValue(data, for: wifiUpdateCharacteristic, type: .withResponse)
        }
    }
    
    public func sendWifiUpdate() {
        print("Attempting")
        sendWifiConfiguration()
    }
}

extension Doorbell {
    struct State: Equatable {
        var ssid = ""
        var psk = ""
        
        var isAssociated = false
        var associationCode = ""
    }
}

extension Doorbell {
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Found: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            #warning("UNFINISHED")
                case Doorbell.SSID_UUID:
                    self.ssidCharacteristic = characteristic
                    
                case Doorbell.PSK_UUID:
                    self.pskCharacteristic = characteristic
                    
                case Doorbell.WIFI_UPDATE_UUID:
                    self.wifiUpdateCharacteristic = characteristic
                    
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
        
        if self.ssidCharacteristic != nil && self.pskCharacteristic != nil && self.wifiUpdateCharacteristic != nil && self.associationCodeCharacteristic != nil && self.associationCodeCharacteristic != nil {
            //skipNextDeviceUpdate = true
            isConnected = true
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }
        
        switch characteristic.uuid {
            case Device.WIFI_UPDATE_UUID:
                break
            case Doorbell.ASSOC_STATE_UUID:
                state.isAssociated = parseBoolean(for: updatedValue)
            case Doorbell.ASSOC_CODE_UUID:
                state.associationCode = parseString(for: updatedValue)
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
        print("here")
    }
    
    private func parseBoolean(for value: Data) -> Bool {
        return value.first == 1
    }
    
    private func parseString(for value: Data) -> String {
        let str = String(decoding: value, as: UTF8.self)
        return str
    }
}

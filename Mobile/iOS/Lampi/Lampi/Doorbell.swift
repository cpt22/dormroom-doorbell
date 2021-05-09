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

class Doorbell: Device, ObservableObject {
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
        if isConnected {
            pendingBluetoothUpdate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.writeSSID()
                self?.writePSK()
                self?.writeUpdate()
                
                self?.pendingBluetoothUpdate = false
            }
        }
    }
    
    private func writeSSID() {
        if let ssidCharacteristic = ssidCharacteristic {
            let valueString = (state.ssid as NSString).data(using: String.Encoding.utf8.rawValue)
            devicePeripheral?.writeValue(valueString!, for: ssidCharacteristic, type: .withResponse)
        }
    }
    
    private func writePSK() {
        if let pskCharacteristic = pskCharacteristic {
            let valueString = (state.psk as NSString).data(using: String.Encoding.utf8.rawValue)
            devicePeripheral?.writeValue(valueString!, for: pskCharacteristic, type: .withResponse)
        }
    }
    
    private func writeUpdate() {
        if let wifiUpdateCharacteristic = wifiUpdateCharacteristic {
            var val: UInt8 = 5
            let data = Data(bytes: &val, count: 1)
            devicePeripheral?.writeValue(data, for: wifiUpdateCharacteristic, type: .withResponse)
        }
    }
    
    public func sendWifiUpdate() {
        sendWifiConfiguration()
    }
}

extension Doorbell {
    struct State: Equatable {
        var ssid = ""
        var psk = ""
        var wifiResponse = ""
        
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
            print(characteristic.uuid)
            switch characteristic.uuid {
            #warning("UNFINISHED")
                case Doorbell.SSID_UUID:
                    self.ssidCharacteristic = characteristic
                    
                case Doorbell.PSK_UUID:
                    self.pskCharacteristic = characteristic
                    
                case Doorbell.WIFI_UPDATE_UUID:
                    self.wifiUpdateCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    
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
            isConnected = true
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }
        
        switch characteristic.uuid {
            case Device.WIFI_UPDATE_UUID:
                if (parseBoolean(for: updatedValue)) {
                    state.wifiResponse = "WiFi Updated"
                } else {
                    state.wifiResponse = "Error in WiFi configuration!"
                }
                print(parseBoolean(for: updatedValue))
                break
            case Doorbell.ASSOC_STATE_UUID:
                state.isAssociated = parseBoolean(for: updatedValue)
            case Doorbell.ASSOC_CODE_UUID:
                state.associationCode = parseString(for: updatedValue)
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    private func parseBoolean(for value: Data) -> Bool {
        print(value.first)
        return value.first == 1
    }
    
    private func parseString(for value: Data) -> String {
        let str = String(decoding: value, as: UTF8.self)
        return str
    }
}

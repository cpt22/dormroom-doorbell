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

class Doorbell: NSObject, ObservableObject {
    let name: String
    @Published var state = State()
    
    private var ssidCharacteristic: CBCharacteristic?
    private var pskCharacteristic: CBCharacteristic?
    private var wifiUpdateCharacteristic: CBCharacteristic?
    
    private var associationCodeCharacteristic: CBCharacteristic?
    private var associationStateCharacteristic: CBCharacteristic?
    
    // MARK: State Tracking
    private var skipNextDeviceUpdate = false
    private var pendingBluetoothUpdate = false
    
    private func setupPeripheral() {
        if let doorbellPeripheral = doorbellPeripheral {
            doorbellPeripheral.delegate = self
        }
    }
    
    var doorbellPeripheral: CBPeripheral? {
        didSet {
            setupPeripheral()
        }
    }
    
    init(name: String) {
        self.name = name
        super.init()
        
        //self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    init(doorbellPeripheral: CBPeripheral) {
        guard let peripheralName = doorbellPeripheral.name else {
            fatalError("Doorbell must be initialized with a peripheral with a name")
        }
        
        self.doorbellPeripheral = doorbellPeripheral
        self.name = peripheralName
        
        super.init()
        
        self.setupPeripheral()
    }
    
}

extension Doorbell {
    static let DOORBELL_SERVICE_UUID = CBUUID(string: "9770695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_CODE_UUID = CBUUID(string: "9771695f-2ca0-4144-af5d-90a86d82ab40")
    static let ASSOC_STATE_UUID = CBUUID(string: "9772695f-2ca0-4144-af5d-90a86d82ab40")
    
    static let WIFI_SERVICE_UUID = CBUUID(string: "08c7042c-12da-49e8-845e-6086d18a81fa")
    static let SSID_UUID = CBUUID(string: "18c7042c-12da-49e8-845e-6086d18a81fa")
    static let PSK_UUID = CBUUID(string: "28c7042c-12da-49e8-845e-6086d18a81fa")
    static let WIFI_UPDATE_UUID = CBUUID(string: "38c7042c-12da-49e8-845e-6086d18a81fa")
    
    private var shouldSkipUpdateDevice: Bool {
        return skipNextDeviceUpdate || pendingBluetoothUpdate
    }
    
    private func sendWifiConfiguration(force: Bool = false) {
        if state.isConnected && (force || !shouldSkipUpdateDevice) {
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
            doorbellPeripheral?.writeValue(valueString!, for: ssidCharacteristic, type: .withResponse)
        }
    }
    
    private func writePSK() {
        if let pskCharacteristic = pskCharacteristic {
            let valueString = (state.psk as NSString).data(using: String.Encoding.utf8.rawValue)
            doorbellPeripheral?.writeValue(valueString!, for: pskCharacteristic, type: .withResponse)
        }
    }
    
    private func writeUpdate() {
        if let wifiUpdateCharacteristic = wifiUpdateCharacteristic {
            var val: UInt8 = 1
            let data = Data(bytes: &val, count: 1)
            doorbellPeripheral?.writeValue(data, for: wifiUpdateCharacteristic, type: .withResponse)
        }
    }
}

extension Doorbell {
    struct State: Equatable {
        var isConnected = false
        var ssid = ""
        var psk = ""
        
        var isAssociated = false
        var associationCode = ""
    }
}

extension Doorbell: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Found: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            #warning("UNFINISHED")
                case Doorbell.SSID_UUID:
                    self.ssidCharacteristic = characteristic
                    break
                case Doorbell.PSK_UUID:
                    self.pskCharacteristic = characteristic
                    break
                case Doorbell.WIFI_UPDATE_UUID:
                    self.wifiUpdateCharacteristic = characteristic
                    break
                case Doorbell.ASSOC_STATE_UUID:
                    self.associationStateCharacteristic = characteristic
                    break
                case Doorbell.ASSOC_CODE_UUID:
                    self.associationCodeCharacteristic = characteristic
                    break
                default:
                    continue
            }
        }
        
        if self.ssidCharacteristic != nil && self.pskCharacteristic != nil && self.wifiUpdateCharacteristic != nil && self.associationCodeCharacteristic != nil && self.associationCodeCharacteristic != nil {
            //skipNextDeviceUpdate = true
            state.isConnected = true
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    private func parseString(for value: Data) -> String {
        return ""
    }
}

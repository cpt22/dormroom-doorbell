//
//  Device.swift
//  Lampi
//
//  Created by Christian Tingle on 5/9/21.
//

import Foundation
import CoreBluetooth
import Combine
import Mixpanel

class Device: NSObject, ObservableObject {
    @Published var wifiState = WifiState()
    
    public let name: String
    public var managerConnected = false
    
    private var ssidCharacteristic: CBCharacteristic?
    private var pskCharacteristic: CBCharacteristic?
    private var wifiUpdateCharacteristic: CBCharacteristic?

    // MARK: State Tracking
    public var skipNextDeviceUpdate = false
    public var pendingBluetoothUpdate = false
    
    public func setupPeripheral() {
        if let devicePeripheral = devicePeripheral {
            devicePeripheral.delegate = self
        }
    }
    
    var devicePeripheral: CBPeripheral? {
        didSet {
            setupPeripheral()
        }
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }
    
    init(devicePeripheral: CBPeripheral) {
        guard let peripheralName = devicePeripheral.name else {
            fatalError("Doorbell must be initialized with a peripheral with a name")
        }
        
        self.devicePeripheral = devicePeripheral
        self.name = peripheralName
        
        super.init()
        
        self.setupPeripheral()
    }
    
    public func isConnected() -> Bool {
        return self.ssidCharacteristic != nil && self.pskCharacteristic != nil && self.wifiUpdateCharacteristic != nil && managerConnected
    }
    
    public func refresh() {
        
    }
}

extension Device {
    static let WIFI_SERVICE_UUID = CBUUID(string: "08c7042c-12da-49e8-845e-6086d18a81fa")
    static let SSID_UUID = CBUUID(string: "18c7042c-12da-49e8-845e-6086d18a81fa")
    static let PSK_UUID = CBUUID(string: "28c7042c-12da-49e8-845e-6086d18a81fa")
    static let WIFI_UPDATE_UUID = CBUUID(string: "38c7042c-12da-49e8-845e-6086d18a81fa")
    
    public var shouldSkipUpdateDevice: Bool {
        return skipNextDeviceUpdate || pendingBluetoothUpdate
    }
    
    private func sendWifiConfiguration(force: Bool = false) {
        if isConnected() {
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
            let valueString = (wifiState.ssid as NSString).data(using: String.Encoding.utf8.rawValue)
            devicePeripheral?.writeValue(valueString!, for: ssidCharacteristic, type: .withResponse)
        }
    }
    
    private func writePSK() {
        if let pskCharacteristic = pskCharacteristic {
            let valueString = (wifiState.psk as NSString).data(using: String.Encoding.utf8.rawValue)
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

extension Device {
    struct WifiState: Equatable {
        var ssid = ""
        var psk = ""
        var wifiResponse = ""
    }
}

extension Device: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Found: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        managerConnected = true
        print(managerConnected)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
                case Doorbell.SSID_UUID:
                    self.ssidCharacteristic = characteristic
                    
                case Doorbell.PSK_UUID:
                    self.pskCharacteristic = characteristic
                    
                case Doorbell.WIFI_UPDATE_UUID:
                    self.wifiUpdateCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                default:
                    continue
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }
        
        switch characteristic.uuid {
            case Device.WIFI_UPDATE_UUID:
                if (parseBoolean(for: updatedValue)) {
                    wifiState.wifiResponse = "WiFi Updated"
                    wifiState.ssid = ""
                    wifiState.psk = ""
                    Mixpanel.mainInstance().trackUIEvent("WiFi Configuration Change",
                                                         properties: ["status":"success"])
                } else {
                    wifiState.wifiResponse = "Error in WiFi configuration!"
                    Mixpanel.mainInstance().trackUIEvent("WiFi Configuration Change",
                                                         properties: ["status":"failure"])
                }
                break
            default:
                break
        }
    }
    
    public func parseBoolean(for value: Data) -> Bool {
        return value.first == 1
    }
    
    public func parseString(for value: Data) -> String {
        let str = String(decoding: value, as: UTF8.self)
        return str
    }
}

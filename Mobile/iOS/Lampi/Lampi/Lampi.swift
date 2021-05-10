//
//  Lampi.swift
//  Lampi
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

class Lampi: Device {
    var state = State() {
        didSet {
            if oldValue != state {
                updateDevice()
            }
        }
        willSet {
            self.objectWillChange.send()
        }
    }
    /*@Published var state = State() {
        didSet {
            if oldValue != state {
                updateDevice()
            }
        }
    }*/
    
    private var bluetoothManager: CBCentralManager?
    
    private var hsvCharacteristic: CBCharacteristic?
    private var brightnessCharacteristic: CBCharacteristic?
    private var onOffCharacteristic: CBCharacteristic?

    override init(name: String) {
        super.init(name: name)
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }

    override init(devicePeripheral: CBPeripheral) {
        super.init(devicePeripheral: devicePeripheral)
    }
}

extension Lampi {
    static let SERVICE_UUID = CBUUID(string: "0001A7D3-D8A4-4FEA-8174-1736E808C066")
    static let HSV_UUID = CBUUID(string: "0002A7D3-D8A4-4FEA-8174-1736E808C066")
    static let BRIGHTNESS_UUID = CBUUID(string: "0003A7D3-D8A4-4FEA-8174-1736E808C066")
    static let ON_OFF_UUID = CBUUID(string: "0004A7D3-D8A4-4FEA-8174-1736E808C066")

    private func updateDevice(force: Bool = false) {
        if state.isConnected && (force || !shouldSkipUpdateDevice) {
            pendingBluetoothUpdate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.writeOnOff()
                self?.writeBrightness()
                self?.writeHSV()

                self?.pendingBluetoothUpdate = false
            }
        }

        skipNextDeviceUpdate = false
    }

    private func writeOnOff() {
        if let onOffCharacteristic = onOffCharacteristic {
            let data = Data(bytes: &state.isOn, count: 1)
            devicePeripheral?.writeValue(data, for: onOffCharacteristic, type: .withResponse)
        }
    }

    private func writeHSV() {
        if let hsvCharacteristic = hsvCharacteristic {
            var hsv: UInt32 = 0
            let hueInt = UInt32(state.hue * 255.0)
            let satInt = UInt32(state.saturation * 255.0)
            let valueInt = UInt32(255)

            hsv = hueInt
            hsv += satInt << 8
            hsv += valueInt << 16

            let data = Data(bytes: &hsv, count: 3)
            devicePeripheral?.writeValue(data, for: hsvCharacteristic, type: .withResponse)
        }
    }

    private func writeBrightness() {
        if let brightnessCharacteristic = brightnessCharacteristic {
            var brightnessChar = UInt8(state.brightness * 255.0)
            let data = Data(bytes: &brightnessChar, count: 1)
            devicePeripheral?.writeValue(data, for: brightnessCharacteristic, type: .withResponse)
        }
    }
}

extension Lampi {
    struct State: Equatable {
        var isConnected = false
        var isOn = false
        var hue: Double = 0.0
        var saturation: Double = 1.0
        var brightness: Double = 1.0

        var color: Color {
            Color(hue: hue, saturation: saturation, brightness: brightness)
        }

        var baseHueColor: Color {
            Color(hue: hue, saturation: 1.0, brightness: 1.0)
        }
    }
}

extension Lampi: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            bluetoothManager?.scanForPeripherals(withServices: [Lampi.SERVICE_UUID])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == name {
            print("Found \(name)")

            devicePeripheral = peripheral

            bluetoothManager?.stopScan()
            bluetoothManager?.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral \(peripheral)")
        peripheral.delegate = self
        peripheral.discoverServices([Lampi.SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral \(peripheral)")
        state.isConnected = false
        bluetoothManager?.connect(peripheral)
    }
}

extension Lampi {
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
            case Lampi.HSV_UUID:
                self.hsvCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            case Lampi.BRIGHTNESS_UUID:
                self.brightnessCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            case Lampi.ON_OFF_UUID:
                self.onOffCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

            default:
                continue
            }
        }

        // not connected until all characteristics are discovered
        if self.hsvCharacteristic != nil && self.brightnessCharacteristic != nil && self.onOffCharacteristic != nil {
            skipNextDeviceUpdate = true
            state.isConnected = true
        }
    }

    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        super.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
        
        skipNextDeviceUpdate = true

        guard let updatedValue = characteristic.value,
              !updatedValue.isEmpty else { return }

        switch characteristic.uuid {
        case Lampi.HSV_UUID:

            var newState = state

            let hsv = parseHSV(for: updatedValue)
            newState.hue = hsv.hue
            newState.saturation = hsv.saturation

            state = newState

        case Lampi.BRIGHTNESS_UUID:
            state.brightness = parseBrightness(for: updatedValue)

        case Lampi.ON_OFF_UUID:
            state.isOn = parseOnOff(for: updatedValue)

        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }

    private func parseOnOff(for value: Data) -> Bool {
        return value.first == 1
    }

    private func parseHSV(for value: Data) -> (hue: Double, saturation: Double) {
        return (hue: Double(value[0]) / 255.0,
                saturation: Double(value[1]) / 255.0)
    }

    private func parseBrightness(for value: Data) -> Double {
        return Double(value[0]) / 255.0
    }
}

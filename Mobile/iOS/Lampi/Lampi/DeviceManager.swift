//
//  DeviceManager.swift
//  Lampi
//

import Foundation
import CoreBluetooth

class DeviceManager: NSObject, ObservableObject {
    @Published var isScanning = true

    var foundDevices: [Lampi] {
        return Array(devices.values)
    }

    private var devices = [String: Lampi]()

    private var bluetoothManager: CBCentralManager!

    override init() {
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension DeviceManager: CBCentralManagerDelegate {
    func scanForDevices() {
        if bluetoothManager.state == .poweredOn {
            isScanning = true
            print("Scanning for Lampis")
            bluetoothManager.scanForPeripherals(withServices: [Lampi.SERVICE_UUID])
            scheduleStopScan()
        }
    }

    private func scheduleStopScan() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            if !(self?.devices.isEmpty ?? true) {
                self?.bluetoothManager.stopScan()
                self?.isScanning = false
            } else {
                print("Still scanning for devices")
                self?.scheduleStopScan()
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanForDevices()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if let peripheralName = peripheral.name {
            print("Manager found device: \(peripheralName)")

            let lampi = Lampi(lampiPeripheral: peripheral)
            devices[peripheralName] = lampi

            bluetoothManager.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Manager Connected to peripheral \(peripheral)")
        peripheral.discoverServices([Lampi.SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let peripheralName = peripheral.name,
           let lampi = devices[peripheralName] {
            print("Manager Disconnected from peripheral \(peripheral)")

            lampi.state.isConnected = false
            bluetoothManager.connect(peripheral)
        }
    }
}

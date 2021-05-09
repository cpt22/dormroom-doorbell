//
//  Device.swift
//  Lampi
//
//  Created by Christian Tingle on 5/9/21.
//

import Foundation
import CoreBluetooth
import Combine
import SwiftUI

class Device: NSObject, ObservableObject{
    public let name: String
    public var isConnected = false

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
}

extension Device {
    public var shouldSkipUpdateDevice: Bool {
        return skipNextDeviceUpdate || pendingBluetoothUpdate
    }
}

extension Device: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        preconditionFailure("This method must be overridden")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        preconditionFailure("This method must be overridden")
    }
}

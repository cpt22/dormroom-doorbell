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
    
    // MARK: State Tracking
    private var skipNextDeviceUpdate = false
    private var pendingBluetoothUpdate = false
    
    
    
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
}

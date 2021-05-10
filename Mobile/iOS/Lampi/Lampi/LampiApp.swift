//
//  LampiApp.swift
//  Lampi
//

import SwiftUI
import Mixpanel

@main
struct LampiApp: App {
    #warning("Update MIXPANEL_TOKEN")
    let MIXPANEL_TOKEN = "INSERT MIXPANEL TOKEN HERE"

    init() {
        Mixpanel.initialize(token: MIXPANEL_TOKEN)
        Mixpanel.mainInstance().registerSuperProperties(["interface": "iOS"])
    }

    var body: some Scene {
        WindowGroup {
            DeviceBroswerView()
        }
    }
}

extension MixpanelInstance {
    func trackUIEvent(_ event: String?, properties: Properties = [:]) {
        var eventProperties = properties
        eventProperties["event_type"] = "ui"

        track(event: event, properties: eventProperties)
    }
}

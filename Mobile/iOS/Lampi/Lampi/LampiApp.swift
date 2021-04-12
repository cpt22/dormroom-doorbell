//
//  LampiApp.swift
//  Lampi
//

import SwiftUI
import Mixpanel
@main
struct LampiApp: App {
    let DEVICE_NAME = "LAMPI b827eb9b7d67"
    let USE_BROWSER = false
    
    let MIXPANEL_TOKEN = "7af93493fe2e2f1830b0438f3aa9f945"

    init() {
            Mixpanel.initialize(token: MIXPANEL_TOKEN)
            Mixpanel.mainInstance().registerSuperProperties(["interface": "iOS"])
        }
    
    var body: some Scene {
        WindowGroup {
            if USE_BROWSER {
                LampiBrowserView()
            } else {
                LampiView(lamp: Lampi(name: DEVICE_NAME))
            }
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

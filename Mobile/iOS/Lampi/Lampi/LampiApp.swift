//
//  LampiApp.swift
//  Lampi
//

import SwiftUI
import Mixpanel

@main
struct LampiApp: App {
    let MIXPANEL_TOKEN = "40e451024cfbd227ff9de81b39b92b47"

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

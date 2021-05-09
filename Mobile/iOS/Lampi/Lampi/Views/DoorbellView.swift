//
//  DoorbellView.swift
//  Lampi
//
//  Created by Prithik Karthikeyan on 5/8/21.
//

import Foundation
import SwiftUI
import Mixpanel



struct DoorbellView: View {
    @ObservedObject var doorbell: Doorbell

    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("WIFI Setup")
                        .padding()
                    HStack {
                        Text("SSID:")
                            .padding()
                        TextField(
                            "Wifi Name",
                            text: $doorbell.state.ssid)
                            .disableAutocorrection(true)
                    }
                    HStack {
                        Text("Password:")
                            .padding()
                        SecureField(
                            "Password",
                            text: $doorbell.state.psk)
                            .disableAutocorrection(true)
                    }

                    Button(action: {
                        doorbell.sendWifiUpdate()
                    }, label: {
                        Text("Save")
                    }).padding()

                }
                VStack {
                    if (doorbell.state.isAssociated) {
                        Text("Doorbell is Associated")
                            .padding()
                    } else {
                        Text("Web Association Code")
                            .padding()
                        HStack {
                            Text(doorbell.state.associationCode.prefix(6))
                        }
                    }
                }

                Spacer()
            }
            .navigationBarTitle("Doorbell Setup", displayMode: .inline)
        }
    }
}

/*struct DoorbellView_Preview: PreviewProvider{
    static var previews: some View{
        DoorbellView()
    }
}*/

//
//  WifiSettingsView.swift
//  Lampi
//
//  Created by Christian Tingle on 5/9/21.
//

import Foundation
import SwiftUI
import Mixpanel

struct WifiSettingsView: View {
    @ObservedObject var device: Device
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("SSID:")
                        .padding()
                    TextField("SSID", text: $device.wifiState.ssid)
                        .disableAutocorrection(true)
                }
                HStack {
                    Text("Password:")
                        .padding()
                    SecureField("Password", text: $device.wifiState.psk)
                        .disableAutocorrection(true)
                }
                Text(device.wifiState.wifiResponse)
                
                Button(action: {
                    device.sendWifiUpdate()
                    UIApplication.shared.endEditing()
                }, label: {
                    Text("Save")
                }).padding()
            }
        }
        Spacer()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Wifi Setup", displayMode: .inline)
        .navigationBarItems(leading: Button(action : {
            self.mode.wrappedValue.dismiss()
        }){
            Image(systemName: "arrow.left")
                .foregroundColor(.blue)
                .shadow(radius: 2.0)
        })
        
    }
    
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

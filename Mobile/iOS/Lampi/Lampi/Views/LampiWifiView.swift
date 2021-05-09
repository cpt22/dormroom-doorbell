//
//  LampiWifiView.swift
//  Lampi
//
//  Created by Prithik Karthikeyan on 5/8/21.
//

import Foundation
import SwiftUI
import Mixpanel



struct LampiWifiView: View {
    @State private var wifiName: String = ""
    @State private var pass: String = ""
    
    var body: some View {
        NavigationView{
        VStack {
                VStack {
                    Text("WIFI Setup")
                                    .padding()
                    HStack {
                        Text("SSID:")
                                        .padding()
                        TextField(
                                   "Wifi Name",
                                    text: $wifiName)
                            .disableAutocorrection(true)
                    }
                    HStack {
                        Text("Password:")
                                        .padding()
                        SecureField(
                                   "Password",
                                    text: $pass)
                                   .disableAutocorrection(true)
                    }
                    
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                        Text("Save")
                    }).padding()

                }
                
                Spacer()
            }
               .navigationBarTitle("Lampi Setup")
        }
    }
}

struct LampiWifiView_Preview: PreviewProvider{
    static var previews: some View{
        LampiWifiView()
    }
}

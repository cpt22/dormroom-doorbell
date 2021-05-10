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
            
            Text("WiFi Setup")
                .padding()
            WifiSettingsView(device: doorbell)
        }
        Spacer()
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action : {
                self.mode.wrappedValue.dismiss()
            }){
                Image(systemName: "arrow.left")
                    .foregroundColor(.blue)
                    .shadow(radius: 2.0)
            })
            .navigationBarTitle("Doorbell Setup", displayMode: .inline)
    }
    
    
}

/*struct DoorbellView_Preview: PreviewProvider{
 static var previews: some View{
 DoorbellView()
 }
 }*/

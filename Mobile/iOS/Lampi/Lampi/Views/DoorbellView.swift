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
                VStack {
                    Text("Web Association Code")
                        .padding([.leading, .trailing, .top, .bottom])
                        .font(
                            .system(size: 22.0, weight: .bold)
                        )
        
                    Text(doorbell.state.associationCode.prefix(6))
                        .font(
                            .system(size: 30.0)
                        )
                }
            }
            
            VStack {
                Text("WiFi Setup")
                    .padding()
                    .font(
                        .system(size: 22.0, weight: .bold)
                    )
                WifiSettingsView(device: doorbell)
            }
            .padding()
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
            .onAppear(perform: doorbell.refresh)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                doorbell.refresh()
            }
    }
}

struct DoorbellView_Preview: PreviewProvider{
    static var previews: some View{
        DoorbellView(doorbell: Doorbell(name: "Poop"))
    }
 }

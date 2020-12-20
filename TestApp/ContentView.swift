//
//  ContentView.swift
//  TestApp
//
//  Created by Kacper on 29/11/2020.
//

import SwiftUI
import VulcanKit

struct ContentView: View {
	let vulcanKit = VulcanKit()
	
	@State var token = "3S1"
	@State var pin = ""
	
    var body: some View {
		NavigationView {
			List {
				TextField("Token", text: $token)
				TextField("PIN", text: $pin)
				Button("Login") {
					guard let certificate: X509 = try? X509(serialNumber: 1, certificateEntries: ["CN": "APP_CERTIFICATE CA Certificate"]) else {
						return
					}
					
					vulcanKit.certificate = certificate
					vulcanKit.login(token: token, symbol: "powiatbochenski", pin: pin, deviceModel: "vulcan internal", deviceSystemVersion: "v0") { string, error in
						print(string ?? "<none>")
						print(error ?? "<none>")
					}
				}
			}
			.navigationTitle(Text("VULCAN INTERNAL"))
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

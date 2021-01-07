//
//  ContentView.swift
//  TestApp
//
//  Created by royal on 29/11/2020.
//

import SwiftUI
import VulcanKit

struct ContentView: View {
	@StateObject var vulcan: VulcanStore = VulcanStore.shared
	@State var token = "3S1"
	@State var pin = ""
	
    var body: some View {
		NavigationView {
			List {
				TextField("Token", text: $token)
				TextField("PIN", text: $pin)
				Button("Login") {
					vulcan.login(token: token, symbol: "powiatbochenski", pin: pin, deviceModel: "vulcan internal") { error in
						if let error = error {
							print("error: \(error)")
						} else {
							print("success")
						}
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

//
//  SetupView.swift
//  Harbour
//
//  Created by royal on 22/03/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// View allowing user to log in
struct SetupView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@Binding var isPresented: Bool
	@Binding var isParentPresented: Bool
	
	var hasParent: Bool = false
	
	@State var token: String = ""
	@State var symbol: String = ""
	@State var pin: String = ""
	
	@State var buttonColor: Color = Color.mainColor
	@State var buttonText: String = "Log in"
	
	private func setButton(color: Color = Color.mainColor, text: String = "Log in") {
		withAnimation {
			self.buttonColor = color
			self.buttonText = text
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				self.buttonColor = Color.mainColor
				self.buttonText = "Log in"
			}
		}
	}
	
    var body: some View {
		VStack(alignment: .center) {			
			Spacer()
			
			Text("SETUP_TITLE")
				.font(.largeTitle)
				.bold()
			
			Spacer()
			
			// Token
			VStack(alignment: .leading) {
				Text("Token")
					.font(.headline)
				TextField("-------", text: $token) {
					let string = self.token
					self.token = self.token.uppercased()
					if (self.token != string) {
						generateHaptic(.light)
					}
				}
				.padding(12)
				.background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
				.disableAutocorrection(true)
				.keyboardType(.alphabet)
				.textContentType(.username)
			}
			.padding()
			
			// Symbol
			VStack(alignment: .leading) {
				Text("Symbol")
					.font(.headline)
				TextField("whateverwhereever", text: $symbol) {
					let string = self.symbol
					self.symbol = self.symbol.lowercased()
					if (self.symbol != string) {
						generateHaptic(.light)
					}
				}
				.padding(12)
				.background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
				.keyboardType(.alphabet)
				.textContentType(.username)
				.disableAutocorrection(true)
			}
			.padding()
			
			// PIN
			VStack(alignment: .leading) {
				Text("PIN")
					.font(.headline)
				TextField("------", text: $pin)
					.padding(12)
					.background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
					.keyboardType(.numberPad)
					.disableAutocorrection(true)
			}
			.padding()
			
			Spacer()
			
			Button(action: {
				if (self.token == "" || self.symbol == "" || self.pin == "") {
					generateHaptic(.error)
					self.setButton(color: Color(UIColor.systemRed), text: "Fill all fields!")
				} else {
					print("[!] (SetupView) Auth data received! Logging in...")
					generateHaptic(.light)
					UIApplication.shared.endEditing()
					self.setButton(text: "Logging in...")
					self.VulcanAPI.login(token: self.token.trimmingCharacters(in: .whitespacesAndNewlines), symbol: self.symbol.trimmingCharacters(in: .whitespacesAndNewlines), pin: Int(self.pin) ?? 0) { success, error in
						self.isParentPresented = !success
						if (error != nil) {
							self.setButton(color: Color(UIColor.systemRed), text: error?.localizedDescription ?? "Error logging in")
							generateHaptic(.error)
						}
					}
				}
			}) {
				Text(buttonText)
					.customButton(buttonColor)
					.multilineTextAlignment(.center)
			}
			.id("Button:" + buttonText)
			
			Text((self.hasParent ? "Go back" : "Nevermind"))
				.font(.callout)
				.bold()
				.padding()
				.onTapGesture {
					withAnimation {
						self.isPresented = false
					}
				}
		}
		.padding()
		.contentShape(Rectangle())
		.modifier(AdaptsToSoftwareKeyboard())
		.onTapGesture {
			UIApplication.shared.endEditing()
		}
		.onAppear {
			self.isParentPresented = !self.VulcanAPI.isLoggedIn
			if (!self.VulcanAPI.hasFirebaseToken) {
				self.VulcanAPI.registerFirebaseDevice()
			}
		}
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
		SetupView(isPresented: .constant(true), isParentPresented: .constant(true), hasParent: true)
			.environmentObject(VulcanAPIModel())
    }
}

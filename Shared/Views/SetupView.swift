//
//  SetupView.swift
//  Harbour
//
//  Created by royal on 22/03/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan

/// View allowing user to log in
struct SetupView: View {
	@Binding var isPresented: Bool
	@Binding var isParentPresented: Bool
	let hasParent: Bool
		
	@State private var token: String = ""
	@State private var symbol: String = ""
	@State private var pin: String = ""
	
	@State private var buttonColor: Color = Color.accentColor
	@State private var buttonText: String = "Log in"
	
	private var cellBackground: some View {
		RoundedRectangle(cornerRadius: 10)
			.fill(Color.secondary.opacity(0.05))
	}
	
	private func setButton(color: Color = Color.accentColor, text: String = "Log in") {
		withAnimation {
			buttonColor = color
			buttonText = text
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
				buttonColor = Color.accentColor
				buttonText = "Log in"
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
				TextField("Token", text: $token, onCommit: {
					let string = token
					token = token.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
					if (token != string) {
						UIDevice.current.generateHaptic(.light)
					}
				})
				.padding(12)
				.background(cellBackground)
				.keyboardType(.alphabet)
				// .textCase(.uppercase)
				.disableAutocorrection(true)
			}
			.padding()
			
			// Symbol
			VStack(alignment: .leading) {
				TextField("Symbol", text: $symbol, onCommit: {
					let string = symbol
					symbol = symbol.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
					if (symbol != string) {
						UIDevice.current.generateHaptic(.light)
					}
				})
				.padding(12)
				.background(cellBackground)
				.keyboardType(.alphabet)
				.disableAutocorrection(true)
			}
			.padding()
			
			// PIN
			VStack(alignment: .leading) {
				TextField("PIN", text: $pin)
					.padding(12)
					.background(cellBackground)
					.keyboardType(.numberPad)
					.disableAutocorrection(true)
			}
			.padding()
			
			Spacer()
			
			Button(action: {
				if (
					token.isReallyEmpty ||
					symbol.isReallyEmpty ||
					pin.isReallyEmpty
				) {
					UIDevice.current.generateHaptic(.error)
					setButton(color: Color(UIColor.systemRed), text: "Fill all fields!")
				} else {
					UIDevice.current.generateHaptic(.light)
					setButton(text: "Logging in...")
					Vulcan.shared.login(token: token.trimmingCharacters(in: .whitespacesAndNewlines), symbol: symbol.trimmingCharacters(in: .whitespacesAndNewlines), pin: Int(pin) ?? 0) { success, error in
						isParentPresented = !success
						if (!success) {
							setButton(color: Color(UIColor.systemRed), text: error?.localizedDescription ?? "Error logging in")
							UIDevice.current.generateHaptic(.error)
						}
					}
				}
			}) {
				Text(LocalizedStringKey(buttonText))
					.multilineTextAlignment(.center)
					.buttonModifier(color: Color.accentColor)
			}
			.keyboardShortcut(.defaultAction)
			.id("Button:" + buttonText)
			.padding(.horizontal)
			
			Button(action: {
				withAnimation {
					isPresented = false
				}
			}) {
				Text((hasParent ? "Go back" : "Nevermind"))
					.font(.body)
					.bold()
					.padding()
			}
			.keyboardShortcut(.cancelAction)
			.padding(.horizontal)
		}
		.padding(.vertical)
		.contentShape(Rectangle())
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
		SetupView(isPresented: .constant(true), isParentPresented: .constant(true), hasParent: true)
    }
}

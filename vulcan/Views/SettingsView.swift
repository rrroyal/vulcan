//
//  SettingsView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// List view, containing list with options and NavigationBar NavigationLink to user list
struct SettingsView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	@State var showingSetupView: Bool = false
	@State var showingResetSheet: Bool = false
	@State var showingResetAlert: Bool = false
	
	var body: some View {
		List {
			// MARK: - User
			SettingsSection(header: "User") {
				// Log in/out
				HStack {
					if (self.VulcanAPI.isLoggedIn) {
						Text("SETTINGS_LOGGEDIN : \(self.VulcanAPI.selectedUser?.UzytkownikLogin ?? "")")
							.font(.body)
							.bold()
							.id("settings:loggedin:" + String(describing: self.VulcanAPI.isLoggedIn))
						Spacer()
						Button(action: {
							generateHaptic(.light)
							withAnimation {
								self.VulcanAPI.logOut()
							}
						}) {
							Text("Log out")
								.foregroundColor(.red)
								.id("settings:logout")
						}
						.id("settings:loggedin")
					} else {
						Text("Not logged in")
							.font(.body)
							.bold()
							.id("settings:notloggedin:")
						Spacer()
						Button(action: {
							generateHaptic(.light)
							withAnimation {
								self.showingSetupView = !self.VulcanAPI.isLoggedIn
							}
						}) {
							Text("Log in")
								.foregroundColor(.mainColor)
								.id("settings:login")
						}
						.id("settings:notloggedin")
					}
				}
				
				// User group
				VStack(alignment: .leading) {
					Text("User group")
						.font(.body)
						.bold()
					Picker("User group", selection: self.$Settings.userGroup) {
						Text("Show all").tag(0)
						Text("1/2").tag(1)
						Text("2/2").tag(2)
					}
					.pickerStyle(SegmentedPickerStyle())
				}
				
				// Mark message as read on open
				VStack(alignment: .leading, spacing: 4) {
					Toggle(isOn: self.$Settings.readMessageOnOpen, label: {
						Text("SETTINGS_READMESSAGEONOPEN")
							.font(.body)
							.bold()
						Spacer()
					})
					Text("SETTINGS_READMESSAGEONOPEN_TOOLTIP")
						.font(.footnote)
						.opacity(0.5)
				}
			}
			
			// MARK: - Interface
			SettingsSection(header: "Interface") {
				// Haptic feedback
				VStack(alignment: .leading, spacing: 4) {
					Toggle(isOn: self.$Settings.hapticFeedback, label: {
						Text("SETTINGS_HAPTICFEEDBACK")
							.font(.body)
							.bold()
						Spacer()
					})
					Text("SETTINGS_HAPTICFEEDBACK_TOOLTIP")
						.font(.footnote)
						.opacity(0.5)
				}
				
				// Colorize grades
				VStack(alignment: .leading, spacing: 4) {
					Toggle(isOn: self.$Settings.colorizeGrades, label: {
						Text("SETTINGS_COLORIZEGRADES")
							.font(.body)
							.bold()
						Spacer()
					})
					Text("SETTINGS_COLORIZEGRADES_TOOLTIP")
						.font(.footnote)
						.opacity(0.5)
				}
				
				if (self.Settings.colorizeGrades) {
					// Colorize grade background
					VStack(alignment: .leading, spacing: 4) {
						Toggle(isOn: self.$Settings.colorizeGradeBackground, label: {
							Text("SETTINGS_COLORIZEGRADEBACKGROUND")
								.font(.body)
								.bold()
							Spacer()
						})
						Text("SETTINGS_COLORIZEGRADEBACKGROUND_TOOLTIP")
							.font(.footnote)
							.opacity(0.5)
					}
					
					// Color scheme
					NavigationLink(destination: ColorSchemeSettingsView().environmentObject(self.Settings)) {
						Text("SETTINGS_COLORSCHEME")
							.font(.body)
							.bold()
					}
				}
			}
			
			// MARK: - Other
			SettingsSection(header: "Other", isLast: true) {
				// Reset button
				Button(action: {
					generateHaptic(.warning)
					self.showingResetSheet = true
				}) {
					HStack {
						Spacer()
						Text("Reset user settings")
							.foregroundColor(.red)
						Spacer()
					}
				}
				.actionSheet(isPresented: self.$showingResetSheet) {
					ActionSheet(title: Text("SETTINGS_RESET"), message: Text("SETTINGS_RESET_TOOLTIP"), buttons: [
						.destructive(Text("Reset")) {
							generateHaptic(.medium)
							self.Settings.resetSettings()
							self.showingResetAlert = true
						},
						.cancel(Text("Nevermind"))
					])
				}
				.alert(isPresented: self.$showingResetAlert) { () -> Alert in
					Alert(title: Text("Done!"), message: Text("SETTINGS_RESETTED"), primaryButton: .destructive(Text("Yes"), action: { print("[!] Exiting."); exit(0) }), secondaryButton: .default(Text("No")))
				}
			}
		}
		.listStyle(GroupedListStyle())
		.environment(\.horizontalSizeClass, .regular)
		.navigationBarTitle(Text("Settings"))
		.navigationBarItems(trailing: NavigationLink(destination: UsersView().environmentObject(VulcanAPI).environmentObject(Settings)) {
				Image(systemName: "person.circle")
					.navigationBarButton(edge: .trailing)
			}
		)
		.navigationViewStyle(StackNavigationViewStyle())
			.sheet(isPresented: self.$showingSetupView, content: { SetupView(isPresented: self.$showingSetupView, isParentPresented: self.$showingSetupView, hasParent: false).environmentObject(self.VulcanAPI) })
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
	}
}

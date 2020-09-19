//
//  SettingsView.swift
//  iOS
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import UserNotifications

/// View containing licenses of the used libraries.
fileprivate struct LegalView: View {
	let KeychainAccessLicense: String = "The MIT License (MIT)\nCopyright (c) 2014 kishikawa katsumi\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
	let KeychainAccessURL: URL? = URL(string: "https://github.com/kishikawakatsumi/KeychainAccess")!
	
	var body: some View {
		List {
			// KeychainAccess
			DisclosureGroup("KeychainAccess") {
				Text(KeychainAccessLicense)
					.font(.system(.body, design: .monospaced))
					.onTapGesture {
						guard let url = KeychainAccessURL else { return }
						generateHaptic(.light)
						UIApplication.shared.open(url)
					}
			}
			.padding(.vertical)
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Libraries"))
	}
}

/// View showing list of available color schemes.
fileprivate struct ColorSchemeSettingsView: View {
	@EnvironmentObject var settings: SettingsModel
	@AppStorage(UserDefaults.AppKeys.colorScheme.rawValue, store: .group) var colorScheme: String = "Default"
	
	var body: some View {
		List(Bundle.main.colorSchemes, id: \.self) { (scheme) in
			HStack {
				VStack(alignment: .leading) {
					Text(LocalizedStringKey(scheme))
						.font(.headline)
						.padding(.bottom, 2)
					
					HStack {
						Text("6").foregroundColor(Color("ColorSchemes/\(scheme)/6", bundle: Bundle(identifier: "Colors")))
						Text("5").foregroundColor(Color("ColorSchemes/\(scheme)/5", bundle: Bundle(identifier: "Colors")))
						Text("4").foregroundColor(Color("ColorSchemes/\(scheme)/4", bundle: Bundle(identifier: "Colors")))
						Text("3").foregroundColor(Color("ColorSchemes/\(scheme)/3", bundle: Bundle(identifier: "Colors")))
						Text("2").foregroundColor(Color("ColorSchemes/\(scheme)/2", bundle: Bundle(identifier: "Colors")))
						Text("1").foregroundColor(Color("ColorSchemes/\(scheme)/1", bundle: Bundle(identifier: "Colors")))
						Text("-").foregroundColor(Color("ColorSchemes/\(scheme)/0", bundle: Bundle(identifier: "Colors")))
					}
				}
				
				Spacer()
				
				if (colorScheme == scheme) {
					Image(systemName: "checkmark")
						.font(.headline)
				}
			}
			.id(scheme)
			.padding(.vertical, 10)
			.contentShape(Rectangle())
			.onTapGesture {
				colorScheme = scheme
				generateHaptic(.light)
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Color Scheme"))
	}
}

/// View showing list of available app icons.
fileprivate struct AppIconView: View {
	@EnvironmentObject var settings: SettingsModel
	
	var body: some View {
		List(Bundle.main.appIcons, id: \.self) { (icon) in
			HStack {
				Image(icon)
					.cornerRadius(16)
				
				Spacer()
				
				if (Bundle.main.currentAppIcon == icon) {
					Image(systemName: "checkmark")
						.font(.headline)
				}
			}
			.id(icon)
			.padding(.vertical, 10)
			.contentShape(Rectangle())
			.onTapGesture {
				if (Bundle.main.currentAppIcon != icon) {
					generateHaptic(.light)
				}
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("App Icon"))
	}
}

/// Component used as a setting option cell.
fileprivate struct SettingsOption: View {
	@Binding var setting: Bool
	let title: String
	let subtitle: String
	
	var body: some View {
		VStack(alignment: .leading) {
			Toggle(isOn: $setting, label: {
				Text(LocalizedStringKey(title))
					.font(.body)
					.bold()
				Spacer()
			})
			.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			
			Text(LocalizedStringKey(subtitle))
				.font(.footnote)
				.foregroundColor(.secondary)
				.lineLimit(nil)
		}
	}
}

/// List view, containing list with options and NavigationBar NavigationLink to user list.
struct SettingsView: View {
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	
	@State private var showingSetupView: Bool = false
	@State private var showingResetSheet: Bool = false
	@State private var showingResetAlert: Bool = false
	
	@AppStorage(UserDefaults.AppKeys.enableNotifications.rawValue, store: .group) private var enableNotifications: Bool = false
	
	/// App credits, displayed as the footer of the last settings section.
	private var appCredits: some View {
		VStack {
			Group {
				Text("Made with ❤️ (and ☕️) by @rrroyal")
					.bold()
				Text("Version \(Bundle.main.buildVersion) (Build \(Bundle.main.buildNumber))")
					.bold()
				#if DEBUG
				Text("🚧 DEBUG 🚧")
					.bold()
				#endif
			}
			.font(.callout)
			.opacity(0.2)
			.multilineTextAlignment(.center)
			.foregroundColor(.primary)
		}
		.fullWidth()
		.padding()
		.edgesIgnoringSafeArea(.bottom)
		.onTapGesture {
			guard let url = URL(string: "https://vulcan.shameful.xyz") else { return }
			generateHaptic(.light)
			UIApplication.shared.open(url)
		}
	}
	
	var body: some View {
		List {
			// MARK: - User
			Section(header: Text("General").sectionTitle()) {
				// Log in/out
				HStack {
					if (vulcan.currentUser != nil) {
						Text("SETTINGS_LOGGEDIN : \(vulcan.currentUser?.userLogin ?? "")")
							.font(.body)
							.bold()
							.id("settings:loggedin:" + String(describing: vulcan.currentUser != nil))
						Spacer()
						Button(action: {
							generateHaptic(.light)
							vulcan.logOut()
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
								showingSetupView = true
							}
						}) {
							Text("Log in")
								.foregroundColor(.accentColor)
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
					Picker("User group", selection: $settings.userGroup) {
						Text("1/2").tag(1)
						Text("2/2").tag(2)
					}
					.pickerStyle(SegmentedPickerStyle())
				}
				
				// Mark message as read on open
				SettingsOption(setting: $settings.readMessageOnOpen, title: "SETTINGS_READMESSAGEONOPEN", subtitle: "SETTINGS_READMESSAGEONOPEN_TOOLTIP")
				
				// Schedule notifications
				SettingsOption(setting: $settings.enableNotifications, title: "SETTINGS_ENABLENOTIFICATIONS", subtitle: "SETTINGS_ENABLENOTIFICATIONS_TOOLTIP")
					.onChange(of: enableNotifications) { enabled in
						if !enabled {
							let center = UNUserNotificationCenter.current()
							center.removeAllDeliveredNotifications()
							center.removeAllPendingNotificationRequests()
							
							return
						}
						
						vulcan.schedule
							.flatMap(\.events)
							.filter { $0.dateStarts != nil && $0.dateStarts ?? $0.date >= Date() }
							.filter { $0.group ?? settings.userGroup == settings.userGroup }
							.forEach { event in
								vulcan.addScheduleEventNotification(event)
							}
						
						vulcan.tasks.combined
							.filter { $0.date >= Date() }
							.forEach { task in
								vulcan.addTaskNotification(task)
							}
					}
			}
			.padding(.vertical, 10)

			// MARK: - Interface
			Section(header: Text("Interface").sectionTitle()) {
				// Filter schedule
				SettingsOption(setting: $settings.filterSchedule, title: "SETTINGS_FILTERSCHEDULE", subtitle: "SETTINGS_FILTERSCHEDULE_TOOLTIP")
				
				// Colorize grades
				SettingsOption(setting: $settings.colorizeGrades, title: "SETTINGS_COLORIZEGRADES", subtitle: "SETTINGS_COLORIZEGRADES_TOOLTIP")
				
				// Haptic feedback
				if (DeviceInfo.supportsHapticsOrVibration) {
					SettingsOption(setting: $settings.hapticFeedback, title: "SETTINGS_HAPTICFEEDBACK", subtitle: "SETTINGS_HAPTICFEEDBACK_TOOLTIP")
				}
								
				// Color scheme
				if (settings.colorizeGrades) {
					NavigationLink(destination: ColorSchemeSettingsView()) {
						Text("Color Scheme")
							.font(.body)
							.bold()
					}
				}
				
				// App icon
				if (Bundle.main.appIcons.count > 1) {
					NavigationLink(destination: AppIconView()) {
						Text("App Icon")
							.font(.body)
							.bold()
					}
				}
			}
			.padding(.vertical, 10)

			// MARK: - Other
			Section(header: Text("Other").sectionTitle(), footer: appCredits) {
				// Legal
				NavigationLink(destination: LegalView()) {
					Text("Libraries")
						.font(.body)
						.bold()
				}
				
				#if DEBUG
				NavigationLink(destination: DebugView()) {
					Text("🤫")
						.font(.body)
						.bold()
				}
				#endif
				
				if (settings.updatesAvailable) {
					HStack {
						Spacer()
						Button(action: {
							guard let url = URL(string: "https://github.com/rrroyal/vulcan/releases/latest") else { return }
							generateHaptic(.light)
							UIApplication.shared.open(url)
						}) {
							Text("New update available!")
								.bold()
						}
						Spacer()
					}
				}
				
				// Reset button
				Button(action: {
					generateHaptic(.warning)
					showingResetSheet = true
				}) {
					HStack {
						Spacer()
						Text("Reset user settings")
							.foregroundColor(.red)
						Spacer()
					}
				}
				.actionSheet(isPresented: $showingResetSheet) {
					ActionSheet(title: Text("SETTINGS_RESET"), message: Text("SETTINGS_RESET_TOOLTIP"), buttons: [
						.destructive(Text("Reset")) {
							generateHaptic(.medium)
							settings.resetSettings()
							showingResetAlert = true
						},
						.cancel(Text("Nevermind"))
					])
				}
				.alert(isPresented: $showingResetAlert) { () -> Alert in
					Alert(title: Text("Done!"), message: Text("SETTINGS_RESETTED"), primaryButton: .destructive(Text("Yes"), action: { exit(0) }), secondaryButton: .default(Text("No")))
				}
			}
			.padding(.vertical, 10)
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Settings"))
		.navigationBarItems(trailing: NavigationLink(destination: UsersView()) {
				Image(systemName: "person.circle")
					// .frame(width: 22.5)
					.navigationBarButton(edge: .trailing)
			}
		)
		.sheet(isPresented: $showingSetupView) {
			SetupView(isPresented: $showingSetupView, isParentPresented: $showingSetupView, hasParent: false)
				.environmentObject(vulcan)
		}
	}
}

/* struct SettingsView_Previews: PreviewProvider {
static var previews: some View {
SettingsView()
}
} */

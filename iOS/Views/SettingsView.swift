//
//  SettingsView.swift
//  iOS
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import UserNotifications
import os

/// Component used as a setting option cell.
fileprivate struct SettingsOption: View {
	@Binding var setting: Bool
	let title: String
	let subtitle: String
	
	var body: some View {
		VStack(alignment: .leading) {
			Toggle(isOn: $setting.animation(), label: {
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
	
	@AppStorage(UserDefaults.AppKeys.enableScheduleNotifications.rawValue, store: .group) public var enableScheduleNotifications: Bool = false
	@AppStorage(UserDefaults.AppKeys.enableTaskNotifications.rawValue, store: .group) public var enableTaskNotifications: Bool = false
	
	private let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanApp", category: "Settings")
	
	private func manageScheduleNotifications(enabled: Bool) {
		if !enabled {
			logger.debug("Removing all notifications with identifier \"ScheduleNotification\".")
			UNUserNotificationCenter.current().getPendingNotificationRequests() { notifications in
				let identifiers = notifications.filter({ $0.content.categoryIdentifier.contains("ScheduleNotification") }).map(\.identifier)
				UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
			}
			
			return
		}
		
		UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
			if let error = error {
				logger.error("Error granting notification permission: \(error.localizedDescription)")
			}
			
			logger.debug("Granted notification permissions: \(granted)")
		}
		
		vulcan.schedule
			.flatMap(\.events)
			.filter { $0.dateStarts != nil && $0.dateStarts ?? $0.date >= Date() }
			.filter { $0.isUserSchedule }
			.forEach { event in
				vulcan.addScheduleEventNotification(event)
			}
	}
	
	private func manageTaskNotifications(enabled: Bool) {
		if !enabled {
			logger.debug("Removing all notifications with identifier \"TaskNotification\".")
			UNUserNotificationCenter.current().getPendingNotificationRequests() { notifications in
				let identifiers = notifications.filter({ $0.content.categoryIdentifier.contains("TaskNotification") }).map(\.identifier)
				UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
			}
			
			return
		}
		
		UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
			if let error = error {
				logger.error("Error granting notification permission: \(error.localizedDescription)")
			}
			
			logger.debug("Granted notification permissions: \(granted)")
		}
		
		vulcan.tasks.combined
			.filter { $0.date >= Date() }
			.forEach { task in
				vulcan.addTaskNotification(task)
			}
	}
	
	private var generalSection: some View {
		Section(header: Text("General").sectionTitle()) {
			// Mark message as read on open
			SettingsOption(setting: $settings.readMessageOnOpen, title: "SETTINGS_READMESSAGEONOPEN", subtitle: "SETTINGS_READMESSAGEONOPEN_TOOLTIP")
		}
		.padding(.vertical, 10)
	}
	
	private var uonetSection: some View {
		Section(header: Text("UONET+").sectionTitle()) {
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
			
			if vulcan.currentUser != nil || vulcan.users.count > 0 {
				NavigationLink(destination: UsersView()) {
					Text("Users")
						.font(.body)
						.bold()
				}
			}
		}
		.padding(.vertical, 10)
	}
	
	private var notificationsSection: some View {
		Section(header: Text("Notifications").sectionTitle()) {
			// Schedule
			SettingsOption(setting: $settings.enableScheduleNotifications, title: "SETTINGS_SCHEDULENOTIFICATIONS", subtitle: "SETTINGS_SCHEDULENOTIFICATIONS_TOOLTIP")
				.onChange(of: enableScheduleNotifications, perform: manageScheduleNotifications)
			
			// Tasks
			SettingsOption(setting: $settings.enableTaskNotifications, title: "SETTINGS_TASKNOTIFICATIONS", subtitle: "SETTINGS_TASKNOTIFICATIONS_TOOLTIP")
				.onChange(of: enableTaskNotifications, perform: manageTaskNotifications)
		}
		.padding(.vertical, 10)
	}
	
	private var interfaceSection: some View {
		Section(header: Text("Interface").sectionTitle()) {
			// Show all schedule events
			SettingsOption(setting: $settings.showAllScheduleEvents, title: "SETTINGS_SCHEDULEALLEVENTS", subtitle: "SETTINGS_SCHEDULEALLEVENTS_TOOLTIP")
			
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
	}
	
	private var otherSection: some View {
		Section(header: Text("Other").sectionTitle(), footer: appCredits) {
			// Legal
			NavigationLink(destination: LicenseView()) {
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
		Form {
			generalSection
			uonetSection
			notificationsSection
			interfaceSection
			otherSection
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Settings"))
		.sheet(isPresented: $showingSetupView) {
			SetupView(isPresented: $showingSetupView, isParentPresented: $showingSetupView, hasParent: false)
		}
	}
}

/* struct SettingsView_Previews: PreviewProvider {
static var previews: some View {
SettingsView()
}
} */

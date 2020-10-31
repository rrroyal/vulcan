//
//  vulcanApp.swift
//  Shared
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

@main
struct vulcanApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@Environment(\.scenePhase) private var scenePhase
	@StateObject private var vulcan: Vulcan = Vulcan.shared
	@StateObject private var settings: SettingsModel = SettingsModel.shared
	@StateObject private var appNotifications: AppNotifications = AppNotifications.shared
	// @StateObject private var appState: AppState = AppState.shared
	
	@State private var currentTab: Tab = .home
	
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView(currentTab: $currentTab)
				.environment(\.managedObjectContext, CoreDataModel.shared.persistentContainer.viewContext)
				.environmentObject(vulcan)
				.environmentObject(settings)
				.environmentObject(appNotifications)
				// .environmentObject(appState)
				.defaultAppStorage(.group)
				.notificationOverlay(appNotifications)
				.onChange(of: scenePhase) { (newPhase) in
					switch newPhase {
						case .active:
							break
						case .inactive:
							break
						case .background:
							if vulcan.currentUser != nil {
								appDelegate.scheduleBackgroundRefresh()
							}
						@unknown default:
							break
					}
				}
				.onOpenURL { url in
					switch (url.host) {
						case "schedule": currentTab = .schedule
						default: break
					}
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").todayActivity") { activity in
					currentTab = .home
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").gradesActivity") { activity in
					currentTab = .grades
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").scheduleActivity") { activity in
					currentTab = .schedule
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").tasksActivity") { activity in
					currentTab = .tasks
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").messagesActivity") { activity in
					currentTab = .messages
				}
        }
		
		#if os(macOS)
		Settings {
			MacSettingsView()
				.environment(\.managedObjectContext, CoreDataModel.shared.persistentContainer.viewContext)
				.defaultAppStorage(.group)
		}
		#endif
    }
}

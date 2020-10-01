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
	
	@State private var currentTab: Tab = .home
	
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView(currentTab: $currentTab)
				.environment(\.managedObjectContext, CoreDataModel.shared.persistentContainer.viewContext)
				.environmentObject(vulcan)
				.environmentObject(settings)
				.environmentObject(appNotifications)
				.defaultAppStorage(.group)
				.notificationOverlay($appNotifications.notificationData)
				.onChange(of: scenePhase) { (newPhase) in
					switch (newPhase) {
						case .active:
							break
						case .inactive:
							break
						case .background:
							appDelegate.scheduleBackgroundRefresh()
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
				/* .onChange(of: vulcan.currentUser) { user in
					appDelegate.setShortcuts(visible: user != nil)
				} */
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

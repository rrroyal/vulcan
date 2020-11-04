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
	@StateObject private var appState: AppState = AppState.shared
		
    @SceneBuilder var body: some Scene {
        WindowGroup {
			ContentView(appState: appState)
				.environment(\.managedObjectContext, CoreDataModel.shared.persistentContainer.viewContext)
				.environmentObject(vulcan)
				.environmentObject(settings)
				.environmentObject(appNotifications)
				// .environmentObject(appState)
				.defaultAppStorage(.group)
				.notificationOverlay(appNotifications)
				.onChange(of: scenePhase) { newPhase in
					switch newPhase {
						case .active:
							if let shortcutItemToProcess = appState.shortcutItemToProcess {
								switch shortcutItemToProcess.type {
									case "ShortcutGrades":		appState.currentTab = .grades
									case "ShortcutSchedule":	appState.currentTab = .schedule
									case "ShortcutTasks":		appState.currentTab = .tasks
									case "ShortcutMessages":	appState.currentTab = .messages
									default:					break
								}
								
								appState.shortcutItemToProcess = nil
							}
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
					switch url.host {
						case "home", "today":		appState.currentTab = .home
						case "grades":				appState.currentTab = .schedule
						case "schedule":			appState.currentTab = .schedule
						case "tasks":				appState.currentTab = .tasks
						case "messages":			appState.currentTab = .messages
						default: 					break
					}
				}
				.onContinueUserActivity(HomeView.activityIdentifier) { _ in appState.currentTab = .home }
				.onContinueUserActivity(GradesView.activityIdentifier) { _ in appState.currentTab = .grades }
				.onContinueUserActivity(ScheduleView.activityIdentifier) { _ in appState.currentTab = .schedule }
				.onContinueUserActivity(ScheduleView.nextScheduleEventActivityIdentifier) { _ in appState.currentTab = .schedule }
				.onContinueUserActivity(TasksView.activityIdentifier) { _ in appState.currentTab = .tasks }
				.onContinueUserActivity(MessagesView.activityIdentifier) { _ in appState.currentTab = .messages }
				// .onContinueUserActivity(ComposeMessageView.activityIdentifier) { _ in appState.currentTab = .messages }
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

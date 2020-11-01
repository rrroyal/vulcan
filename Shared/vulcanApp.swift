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
									case "shortcutGrades":		appState.currentTab = [.grades]
									case "shortcutSchedule":	appState.currentTab = [.schedule]
									case "shortcutTasks":		appState.currentTab = [.tasks]
									case "shortcutMessages":	appState.currentTab = [.messages]
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
						case "schedule": appState.currentTab = [.schedule]
						default: break
					}
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").todayActivity") { activity in
					appState.currentTab = [.home]
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").gradesActivity") { activity in
					appState.currentTab = [.grades]
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").scheduleActivity") { activity in
					appState.currentTab = [.schedule]
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").tasksActivity") { activity in
					appState.currentTab = [.tasks]
				}
				.onContinueUserActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").messagesActivity") { activity in
					appState.currentTab = [.messages]
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

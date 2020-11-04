//
//  AppDelegate.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

#if canImport(UIKit)
import UIKit
#endif

import Combine
import BackgroundTasks
import os
import Vulcan
import WidgetKit

class AppDelegate: UIResponder, UIApplicationDelegate {
	// MARK: - App Lifecycle
	private let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "AppDelegate")
	
	private var cancellableSet: Set<AnyCancellable> = []
	
	/// Called when app is launched
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		// WatchConnectivity session
		WatchSessionManager.shared.startSession()
		
		// UserNotifications
		let notifications: Notifications = Notifications.shared
		notifications.notificationCenter.delegate = notifications
		
		// Background fetch
		BGTaskScheduler.shared.register(forTaskWithIdentifier: "dev.niepostek.vulcan.refreshData", using: nil) { task in
			self.handleAppRefresh(task)
		}
				
		// Listeners
		Vulcan.shared.$currentUser
			.sink { user in
				self.setShortcuts(visible: user != nil)
				
				let watchData: [String: Any] = [
					"type": "Vulcan",
					"data": [
						"currentUser": try? JSONEncoder().encode(user)
					]
				]
				
				try? WatchSessionManager.shared.sendData(watchData)
			}
			.store(in: &cancellableSet)
		
		Vulcan.shared.scheduleDidChange
			.sink { isPersistent in
				if !isPersistent {
					return
				}
				
				// Widgets
				WidgetCenter.shared.reloadTimelines(ofKind: "NextUpWidget")
				WidgetCenter.shared.reloadTimelines(ofKind: "NowWidget")
				
				// Watch
				let watchData: [String: Any] = [
					"type": "Vulcan",
					"data": [
						"schedule": try? JSONEncoder().encode(Vulcan.shared.schedule)
					]
				]
				
				try? WatchSessionManager.shared.sendData(watchData)
			}
			.store(in: &cancellableSet)
		
		return true
	}
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		if let shortcutItem = options.shortcutItem {
			AppState.shared.shortcutItemToProcess = shortcutItem
		}
		
		let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
		sceneConfiguration.delegateClass = CustomSceneDelegate.self
		
		return sceneConfiguration
	}
	
	/// Registered for APNs
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		logger.info("Successfuly registered for APNs. Device token: \(token, privacy: .private).")
	}
	
	/// Failed to register for APNs
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		logger.warning("Failed to register for APNs: \(error.localizedDescription)")
	}
	
	// MARK: - Helper functions
	
	/// Sets the currently visible shortcuts
	/// - Parameter visible: Should shortcuts be visible?
	public func setShortcuts(visible: Bool) {
		if visible {
			UIApplication.shared.shortcutItems = [
				UIApplicationShortcutItem(type: "ShortcutGrades", localizedTitle: "Grades".localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "rosette"), userInfo: nil),	// Grades
				UIApplicationShortcutItem(type: "ShortcutSchedule", localizedTitle: "Schedule".localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "calendar"), userInfo: nil),	// Schedule
				UIApplicationShortcutItem(type: "ShortcutTasks", localizedTitle: "Tasks".localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard"), userInfo: nil), // Tasks
				UIApplicationShortcutItem(type: "ShortcutMessages", localizedTitle: "Messages".localized, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "envelope"), userInfo: nil)	// Messages
				]
		} else {
			UIApplication.shared.shortcutItems = []
		}
	}
	
	// MARK: - Background refresh
	/// Schedules a background refresh task
	public func scheduleBackgroundRefresh() {
		logger.debug("Scheduling app refresh.")
		do {
			let request = BGAppRefreshTaskRequest(identifier: "dev.niepostek.vulcan.refreshData")
			request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
			try BGTaskScheduler.shared.submit(request)
		} catch {
			logger.warning("Error scheduling: \(error.localizedDescription)")
		}
	}
	
	/// Executed when app is launched by background refresh.
	/// - Parameter task: Task to execute
	func handleAppRefresh(_ task: BGTask) {
		if (!UserDefaults.group.bool(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue)) {
			task.setTaskCompleted(success: true)
			return
		}
		
		logger.notice("Refreshing in the background...")
		
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 6
		queue.addOperation { Vulcan.shared.getGrades() }
		
		if let startOfWeek: Date = Date().startOfWeek,
		   let endOfWeek: Date = Date().endOfWeek {
			queue.addOperation { Vulcan.shared.getSchedule(isPersistent: true, from: startOfWeek, to: endOfWeek) }
		}
		
		queue.addOperation { Vulcan.shared.getTasks(isPersistent: true, from: Date().startOfMonth, to: Date().startOfMonth) }
		queue.addOperation { Vulcan.shared.getMessages(tag: .received, isPersistent: true, from: Date().startOfMonth, to: Date().endOfMonth) }
		queue.addOperation { Vulcan.shared.getEndOfTermGrades() }
		
		task.expirationHandler = {
			self.logger.warning("Refresh expired!")
			queue.cancelAllOperations()
		}
		
		let lastOperation = queue.operations.last
		lastOperation?.completionBlock = {
			task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
		}
		
		self.scheduleBackgroundRefresh()
	}
}

class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		AppState.shared.shortcutItemToProcess = shortcutItem
	}
}

//
//  SceneDelegate.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	var currentTab: ScreenPage = .home
	let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		
		// Setup
		let VulcanAPI: VulcanAPIModel = appDelegate.VulcanAPI
		let Settings: SettingsModel = appDelegate.Settings
		
		#if !targetEnvironment(macCatalyst)
		// Set up the quick actions
		if (VulcanAPI.isLoggedIn && UserDefaults.user.isLoggedIn) {
			let shortcutGradesItem = UIApplicationShortcutItem(type: "shortcutGrades", localizedTitle: NSLocalizedString("Grades", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "rosette"), userInfo: nil)
			let shortcutScheduleItem = UIApplicationShortcutItem(type: "shortcutSchedule", localizedTitle: NSLocalizedString("Schedule", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "calendar"), userInfo: nil)
			let shortcutTasksItem = UIApplicationShortcutItem(type: "shortcutTasks", localizedTitle: NSLocalizedString("Tasks", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard.fill"), userInfo: nil)
			let shortcutMessagesItem = UIApplicationShortcutItem(type: "shortcutMessages", localizedTitle: NSLocalizedString("Messages", comment: ""), localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "text.bubble.fill"), userInfo: nil)
			UIApplication.shared.shortcutItems = [shortcutMessagesItem, shortcutTasksItem, shortcutScheduleItem, shortcutGradesItem]
		} else {
			UIApplication.shared.shortcutItems = []
		}
		
		if let shortcutItem = connectionOptions.shortcutItem {
			switch (shortcutItem.type) {
				case "shortcutGrades":		self.currentTab = .grades; VulcanAPI.getGrades(); break
				case "shortcutSchedule":	self.currentTab = .schedule; VulcanAPI.getSchedule(startDate: Date().startOfWeek ?? Date(), endDate: Date().endOfWeek ?? Date()); break
				case "shortcutTasks":		self.currentTab = .tasks; VulcanAPI.getTasks(tag: .exam, startDate: Date().startOfWeek ?? Date(), endDate: Date().endOfWeek ?? Date()); break
				case "shortcutMessages":	self.currentTab = .messages; VulcanAPI.getMessages(tag: .received, startDate: Date().startOfMonth, endDate: Date().endOfMonth); break
				default:					self.currentTab = .home; break
			}
		}
		#endif
		
		// Create the SwiftUI view that provides the window contents.
		let contentView = ContentView(currentTab: self.currentTab)
			.environmentObject(VulcanAPI)
			.environmentObject(Settings)
			.accentColor(Color.mainColor)

		// Use a UIHostingController as window root view controller.
		if let windowScene = scene as? UIWindowScene {
		    let window = UIWindow(windowScene: windowScene)
		    window.rootViewController = UIHostingController(rootView: contentView)
		    self.window = window
		    window.makeKeyAndVisible()
		}
	}

	#if !targetEnvironment(macCatalyst)
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		let VulcanAPI: VulcanAPIModel = appDelegate.VulcanAPI
		switch (shortcutItem.type) {
			case "shortcutGrades":		self.currentTab = .grades; VulcanAPI.getGrades(); break
			case "shortcutSchedule":	self.currentTab = .schedule; VulcanAPI.getSchedule(startDate: Date().startOfWeek ?? Date(), endDate: Date().endOfWeek ?? Date()); break
			case "shortcutTasks":		self.currentTab = .tasks; VulcanAPI.getTasks(tag: .exam, startDate: Date().startOfWeek ?? Date(), endDate: Date().endOfWeek ?? Date()); break
			case "shortcutMessages":	self.currentTab = .messages; VulcanAPI.getMessages(tag: .received, startDate: Date().startOfMonth, endDate: Date().endOfMonth); break
			default:					self.currentTab = .home; break
		}
	}
	#endif

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
		
		if (UserDefaults.user.isLoggedIn) {
			appDelegate.scheduleAppRefresh()
		}
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
		
		if (UserDefaults.user.isLoggedIn) {
			appDelegate.scheduleAppRefresh()
		}
	}
}

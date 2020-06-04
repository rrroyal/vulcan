//
//  AppDelegate.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import UIKit
import CoreData
import Network
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	// MARK: - Core Data stack
	/// Core Data container
	lazy var persistentContainer: NSPersistentContainer = {
		let container: NSPersistentContainer = NSPersistentContainer(name: "VulcanStore")
		
		let storeURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.object(forInfoDictionaryKey: "GroupIdentifier") as? String ?? "")!.appendingPathComponent("vulcan.sqlite")
		let description: NSPersistentStoreDescription = NSPersistentStoreDescription()
		description.shouldInferMappingModelAutomatically = true
		description.shouldMigrateStoreAutomatically = true
		description.url = storeURL
				
		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				print("[!] (CoreData) Could not load store: \(error.localizedDescription)")
				return
			}
			
			print("[*] (CoreData) Store loaded!")
		})
		
		return container
	}()
	
	/// Saves CoreData context
	func saveContext() {
		let context = persistentContainer.viewContext
		
		if (context.hasChanges) {
			do {
				try context.save()
			} catch {
				print("[!] (CoreData) Error saving: \(error.localizedDescription)")
			}
		}
	}
	
	/// Creates or updates CoreData (forgive me)
	/// - Parameters:
	///   - forEntityName: Entity name to search for
	///   - forKey: Key to search/set for
	///   - object: Object that is being set
	func createOrUpdate(forEntityName entityName: String, forKey key: String, value: Data) {
		let context = self.persistentContainer.viewContext
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
		do {
			let response = try context.fetch(fetchRequest)
			if let object = response.first {
				object.setValue(value, forKey: key)
			} else {
				let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
				object.setValue(value, forKey: key)
			}
		} catch {
			print("[!] (CoreData) Could not fetch: \(error)")
		}
		
		self.saveContext()
	}
	
	// Data models
	lazy var VulcanAPI: VulcanAPIModel = VulcanAPIModel()
	lazy var Settings: SettingsModel = SettingsModel()
	
	// Reachability
	public let monitor: NWPathMonitor = NWPathMonitor()
	public var isReachable: Bool {
		get {
			return monitor.currentPath.status == .satisfied
		}
	}
	
	/// Sends notification
	/// - Parameter notificationData: Notification data
	func sendNotification(_ notificationData: NotificationData) {
		self.Settings.notificationData = notificationData
		self.Settings.isNotificationVisible = true
		self.Settings.notificationPublisher.send(true)
	}
	
	// MARK: - application
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		UITextField.appearance().tintColor = UIColor(named: "mainColor")
		UIView.appearance().tintColor = UIColor(named: "mainColor")
		
		// Start reachability
		self.monitor.start(queue: .global())
		
		// CoreData
		let stored = try? self.persistentContainer.viewContext.fetch(VulcanStored.fetchRequest())
		if (stored?.count ?? 0 > 1) {
			print("[*] (CoreData) Multiple \"stored\" objects detected: \(stored?.count ?? 0)")
			
			for (index, element) in stored!.enumerated() {
				if (index == stored?.count ?? 0 - 1) {
					break
				}
				
				self.persistentContainer.viewContext.delete(element as! NSManagedObject)
			}
		}
		
		let dictionary = try? self.persistentContainer.viewContext.fetch(VulcanDictionary.fetchRequest())
		if (dictionary?.count ?? 0 > 1) {
			print("[*] (CoreData) Multiple \"dictionary\" objects detected: \(dictionary?.count ?? 0)")
			
			for (index, element) in dictionary!.enumerated() {
				if (index == dictionary?.count ?? 0 - 1) {
					break
				}
				
				self.persistentContainer.viewContext.delete(element as! NSManagedObject)
			}
		}
		
		self.saveContext()
		
		// User setup
		if (!UserDefaults.user.launchedBefore) {
			UserDefaults.user.hapticFeedback = true
			UserDefaults.user.colorizeGrades = true
			UserDefaults.user.colorizeGradeBackground = true
			UserDefaults.user.savedUserData = nil
			UserDefaults.user.userGroup = 0
			UserDefaults.user.isLoggedIn = false
			UserDefaults.user.readMessageOnOpen = true
		}
		
		// Background fetch
		BGTaskScheduler.shared.register(forTaskWithIdentifier: Bundle.main.object(forInfoDictionaryKey: "BackgroundTaskIdentifier") as? String ?? "", using: nil) { task in
			self.handleAppRefresh(task)
		}
		
		// WCSession
		WatchSessionManager.shared.startSession()
				
		return true
	}

	// MARK: UISceneSession Lifecycle
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
	
	
	// MARK: - Background app refresh
	func handleAppRefresh(_ task: BGTask) {
		if (!UserDefaults.user.isLoggedIn) {
			task.setTaskCompleted(success: true)
			return
		}
		
		print("[!] (Background Refresh) Refreshing...")
		
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 6
		queue.addOperation { self.VulcanAPI.getGrades() }
		queue.addOperation { self.VulcanAPI.getSchedule() }
		queue.addOperation { self.VulcanAPI.getTasks(tag: .exam) }
		queue.addOperation { self.VulcanAPI.getTasks(tag: .homework) }
		queue.addOperation { self.VulcanAPI.getEOTGrades() }
		queue.addOperation { self.VulcanAPI.getMessages(tag: .received, startDate: Date().startOfMonth, endDate: Date().endOfMonth) }
		
		task.expirationHandler = {
			print("[!] (Background Refresh) Expired!")
			queue.cancelAllOperations()
		}
		
		let lastOperation = queue.operations.last
		lastOperation?.completionBlock = {
			task.setTaskCompleted(success: !(lastOperation?.isCancelled ?? false))
		}
		
		scheduleAppRefresh()
	}
	
	func scheduleAppRefresh() {
		print("[!] (Background Refresh) Scheduling app refresh.")
		do {
			let request = BGAppRefreshTaskRequest(identifier: Bundle.main.object(forInfoDictionaryKey: "BackgroundTaskIdentifier") as? String ?? "")
			request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
			try BGTaskScheduler.shared.submit(request)
		} catch {
			print("[!] (Background Refresh) Error scheduling: \(error)")
		}
	}
}

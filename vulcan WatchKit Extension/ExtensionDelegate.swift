//
//  ExtensionDelegate.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 29/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import WatchKit
import WatchConnectivity
import CoreData

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
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
				VulcanAPIStore.shared.loadCached()
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
		
	lazy var VulcanStore: VulcanAPIStore = VulcanAPIStore.shared
	
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
		WatchSessionManager.shared.startSession()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
	
	// MARK: - WatchConnectivity
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("[*] (WCSession) Session activated! State: \(activationState.rawValue)")
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		print("[*] (WCSession) New message!")
	}

}

//
//  CoreDataModel.swift
//  Vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import CoreData
import os

public final class CoreDataModel {
	public static let shared: CoreDataModel = CoreDataModel()
	private let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).CoreData", category: "CoreData")

	private init() { }
	
	lazy public var persistentContainer: NSPersistentContainer = {
		let groupURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.niepostek.vulcanGroup")!.appendingPathComponent("vulcan.sqlite")
		let modelURL = Bundle.module.url(forResource: "VulcanStore", withExtension: "momd")
		let model = NSManagedObjectModel(contentsOf: modelURL!)
		
		let container = NSPersistentContainer(name: "VulcanStore", managedObjectModel: model!)

		let description: NSPersistentStoreDescription = NSPersistentStoreDescription()
		description.url = groupURL
		description.shouldMigrateStoreAutomatically = true
		description.shouldInferMappingModelAutomatically = true
		description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
		description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
		
		container.persistentStoreDescriptions = [description]
		container.loadPersistentStores { storeDescription, error in
			if let error = error {
				self.logger.error("Could not load store: \(error.localizedDescription)")
				self.logger.debug("\(String(describing: storeDescription))")
				self.clearDatabase()
				return
			}
			
			container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
			self.logger.info("Store loaded!")
		}
		
		return container
	}()
	
	/// Saves the CoreData context.
	public func saveContext(force: Bool = false) {
		if self.persistentContainer.viewContext.hasChanges || force {
			do {
				try self.persistentContainer.viewContext.save()
			} catch {
				logger.error("Error saving: \(error.localizedDescription)")
			}
		}
	}
	
	/// Resets the database.
	public func clearDatabase() {
		let urls = persistentContainer.persistentStoreDescriptions.map(\.url)
		let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
		
		logger.debug("Clearing database...")
		
		do {
			let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
			for url in urls {
				guard let url = url else { return }
				try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
				try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
			}
			logger.debug("Done!")
		} catch {
			logger.error("Error: \(error.localizedDescription)")
		}
	}
}

//
//  DataModel.swift
//  vulcan Today Extension
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import CoreData
import Combine

final class DataModel: ObservableObject {
	static let shared = DataModel()
	
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
	
	// @Published var grades: [Vulcan.SubjectGrades] = []
	@Published var schedule: [Vulcan.Day] = []
	// @Published var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	// @Published var messages: Vulcan.Messages = Vulcan.Messages(received: [], sent: [], deleted: [])
	// @Published var notes: [Vulcan.Note] = []
	// @Published var endOfTermGrades: Vulcan.TermGrades = Vulcan.TermGrades(anticipated: [], final: [])
	
	private init() {
		// Load cached data
		let vulcanStored = try? self.persistentContainer.viewContext.fetch(VulcanStored.fetchRequest() as NSFetchRequest)
		if let stored: VulcanStored = vulcanStored?.last as? VulcanStored {
			let decoder = JSONDecoder()
			
			// Schedule
			if let storedSchedule = stored.schedule {
				if let decoded = try? decoder.decode([Vulcan.Day].self, from: storedSchedule) {
					self.schedule = decoded
				}
			}
		}
	}
}

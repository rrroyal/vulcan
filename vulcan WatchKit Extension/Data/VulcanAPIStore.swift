//
//  VulcanAPIStore.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 01/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import Combine
import CoreData
import WatchKit

final class VulcanAPIStore: ObservableObject {
	public static let shared: VulcanAPIStore = VulcanAPIStore()
	
	private let extensionDelegate: ExtensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
	public var dataContainer: NSPersistentContainer
	
	@Published var grades: [Vulcan.SubjectGrades] = []
	@Published var schedule: [Vulcan.Day] = []
	@Published var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	// @Published var messages: Vulcan.Messages = Vulcan.Messages(received: [], sent: [], deleted: [])
	@Published var notes: [Vulcan.Note] = []
	@Published var endOfTermGrades: Vulcan.TermGrades = Vulcan.TermGrades(anticipated: [], final: [])
	
	private init() {
		// Update Core Data context
		self.dataContainer = extensionDelegate.persistentContainer
		
		loadCached()
	}
	
	/// Loads the data from the CoreData to the class variables.
	public func loadCached() {
		print("[*] (VulcanAPIStore) Loading cached.")
		
		// Load cached data
		let vulcanStored = try? self.dataContainer.viewContext.fetch(VulcanStored.fetchRequest() as NSFetchRequest)
		if let stored: VulcanStored = vulcanStored?.last as? VulcanStored {
			let decoder = JSONDecoder()
			
			// Grades
			if let storedGrades = stored.grades {
				if let decoded = try? decoder.decode([Vulcan.SubjectGrades].self, from: storedGrades) {
					self.grades = decoded
				}
			}
			
			// Messages
			/* if let storedMessages = stored.messages {
				if let decoded = try? decoder.decode(Vulcan.Messages.self, from: storedMessages) {
					self.messages = decoded
				}
			} */
			
			// EOT Grades
			if let storedEOTGrades = stored.eotGrades {
				if let decoded = try? decoder.decode(Vulcan.TermGrades.self, from: storedEOTGrades) {
					self.endOfTermGrades = decoded
				}
			}
			
			// Notes
			if let storedNotes = stored.notes {
				if let decoded = try? decoder.decode([Vulcan.Note].self, from: storedNotes) {
					self.notes = decoded
				}
			}
			
			// Schedule
			if let storedSchedule = stored.schedule {
				if let decoded = try? decoder.decode([Vulcan.Day].self, from: storedSchedule) {
					self.schedule = decoded
				}
			}
			
			// Tasks
			if let storedTasks = stored.tasks {
				if let decoded = try? decoder.decode(Vulcan.Tasks.self, from: storedTasks) {
					self.tasks = decoded
				}
			}
		}
	}
}

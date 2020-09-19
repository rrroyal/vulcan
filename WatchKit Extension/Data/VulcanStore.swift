//
//  VulcanStore.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import Foundation
import Vulcan
import os
import CoreData
import ClockKit

final class VulcanStore: ObservableObject {
	private let ud: UserDefaults = UserDefaults.group
	
	static let shared: VulcanStore = VulcanStore()
	
	/// Selected user
	@Published public var currentUser: Vulcan.Student?
	
	/// Data
	@Published public var schedule: [Vulcan.Schedule] = []
	@Published public var grades: [Vulcan.SubjectGrades] = []
	@Published public var eotGrades: [Vulcan.EndOfTermGrade] = []
	@Published public var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	@Published public var receivedMessages: [Vulcan.Message] = []
	
	private init() {
		// Load data
		let context = CoreDataModel.shared.persistentContainer.viewContext
		
		// Student
		if let storedStudents = try? context.fetch(StoredStudent.fetchRequest()) as? [StoredStudent],
		   let storedStudent = storedStudents.first {
			self.currentUser = Vulcan.Student(from: storedStudent)
		}
		
		// Schedule
		if let storedSchedule = try? context.fetch(StoredScheduleEvent.fetchRequest()) as? [StoredScheduleEvent] {
			self.schedule = storedSchedule.grouped
				.map { date, storedEvents in
					let events: [Vulcan.ScheduleEvent] = storedEvents
						.compactMap { entity in
							Vulcan.ScheduleEvent(from: entity)
						}
						.sorted { $0.lessonOfTheDay < $1.lessonOfTheDay }
					
					return Vulcan.Schedule(date: date, events: events)
				}
				.sorted { $0.date < $1.date }
		}
		
		// Grades
		/* if let storedGrades = try? context.fetch(StoredGrade.fetchRequest()) as? [StoredGrade] {
			let dictionary = Dictionary(grouping: storedGrades, by: \.subjectID)
			self.grades = dictionary
				.compactMap { subjectID, grades in
					guard let dictionarySubject: DictionarySubject = dictionarySubjects.first(where: { $0.id == subjectID }),
						  let subjectName: String = dictionarySubject.name,
						  let subjectCode: String = dictionarySubject.code,
						  let dEmployeeID = grades.first?.dEmployeeID,
						  let dictionaryEmployee: DictionaryEmployee = dictionaryEmployees.first(where: { $0.id == dEmployeeID }),
						  let employeeName: String = dictionaryEmployee.name,
						  let employeeSurname: String = dictionaryEmployee.surname,
						  let employeeCode: String = dictionaryEmployee.code
					else {
						return nil
					}
					
					let subject: Vulcan.Subject = Vulcan.Subject(id: Int(dictionarySubject.id), name: subjectName, code: subjectCode, active: dictionarySubject.active, position: Int(dictionarySubject.position))
					let employee: Vulcan.Employee = Vulcan.Employee(id: Int(dictionaryEmployee.id), name: employeeName, surname: employeeSurname, code: employeeCode, active: dictionaryEmployee.active, teacher: dictionaryEmployee.teacher, loginID: Int(dictionaryEmployee.loginID))
					
					let grades: [Vulcan.Grade] = storedGrades
						.map { grade in
							var grade = Grade(from: grade)
							
							if let categoryID = grade.categoryID,
							   let dictionaryGradeCategories: [DictionaryGradeCategory] = try? context.fetch(DictionaryGradeCategory.fetchRequest()) {
								grade.category = dictionaryGradeCategories.first(where: { $0.id == categoryID })
							}
							
							return grade
						}
						.sorted { $0.dateCreatedEpoch < $1.dateCreatedEpoch }
						.filter { $0.subjectID == subject.id }
					
					return Vulcan.SubjectGrades(subject: subject, employee: employee, grades: grades)
				}
				.sorted { $0.subject.name < $1.subject.name }
		} */
		
		// End of Term Grades
		/* if let storedEndOfTermGrades = try? context.fetch(StoredEndOfTermGrade.fetchRequest()) as? [StoredEndOfTermGrade] {
			self.eotGrades = storedEndOfTermGrades
				.compactMap { grade in
					var eotGrade = EndOfTermGrade(from: grade)
					eotGrade?.subject = dictionarySubjects.first(where: { $0.id == grade.subjectID })
					
					return eotGrade
				}
				.sorted { ($0.subject?.name ?? "") < ($1.subject?.name ?? "") }
		} */
		
		// Exams
		if let storedExams = try? context.fetch(StoredExam.fetchRequest()) as? [StoredExam] {
			self.tasks.exams = storedExams
				.compactMap { exam in
					Vulcan.Exam(from: exam)
				}
				.sorted { $0.dateEpoch < $1.dateEpoch }
		}
		
		// Homework
		if let storedHomework = try? context.fetch(StoredHomework.fetchRequest()) as? [StoredHomework] {
			self.tasks.homework = storedHomework
				.compactMap { task in
					Vulcan.Homework(from: task)
				}
				.sorted { $0.dateEpoch < $1.dateEpoch }
		}
		
		// Messages
		if let storedMessages = try? context.fetch(StoredMessage.fetchRequest()) as? [StoredMessage] {
			let receivedMessages: [Vulcan.Message] = storedMessages
				.filter { $0.folder == "Odebrane" && $0.status == "Widoczna" }
				.compactMap { entity in
					let message = Vulcan.Message(from: entity)
					message?.tag = .received
					
					return message
				}
				.sorted { $0.dateSentEpoch > $1.dateSentEpoch }
			
			self.receivedMessages = receivedMessages
		}
	}
	
	/// Sets the default user.
	/// - Parameter user: Selected user
	/// - Parameter force: Force dictionary update
	public func setUser(_ user: Vulcan.Student, force: Bool = false) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "Users")
		logger.debug("Setting default user with ID \(user.id, privacy: .sensitive) (\(user.loginID ?? -1, privacy: .sensitive) : \(user.userLoginID, privacy: .sensitive)).")
		
		ud.setValue(user.id, forKey: UserDefaults.AppKeys.userID.rawValue)
		
		DispatchQueue.main.async {
			self.currentUser = user
		}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		do {
			try context.execute(NSBatchDeleteRequest(fetchRequest: StoredStudent.fetchRequest()))
			_ = user.entity(context: context)
		} catch {
			logger.error("Couldn't execute request: \(error.localizedDescription)")
		}
		
		CoreDataModel.shared.saveContext()
	}
	
	/// Sets the app' schedule.
	/// - Parameter schedule: Schedule received from the phone app
	public func setSchedule(_ schedule: [Vulcan.Schedule]) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "Schedule")
		
		DispatchQueue.main.async {
			self.schedule = schedule
		}
		
		(CLKComplicationServer.sharedInstance().activeComplications ?? [])
			.filter { $0.identifier == "ScheduleComplication" }
			.forEach { complication in
				CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
			}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredScheduleEvent.fetchRequest())
		
		do {
			try context.execute(deleteRequest)
		} catch {
			logger.error("Error executing request: \(error.localizedDescription)")
		}
		
		for event in schedule.flatMap(\.events) {
			_ = event.entity(context: context)
		}
		
		CoreDataModel.shared.saveContext()
	}
	
	/// Sets the app' grades.
	/// - Parameter grades: Received grades
	public func setGrades(_ grades: [Vulcan.SubjectGrades]) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "Grades")
		
		DispatchQueue.main.async {
			self.grades = grades
		}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredGrade.fetchRequest())
		
		do {
			try context.execute(deleteRequest)
		} catch {
			logger.error("Error executing request: \(error.localizedDescription)")
		}
		
		for grade in grades.flatMap(\.grades) {
			_ = grade.entity(context: context)
		}
		
		CoreDataModel.shared.saveContext()
	}
	
	/// Sets the app' EOT grades.
	/// - Parameter eotGrades: End of term grades
	public func setEOTGrades(_ eotGrades: [Vulcan.EndOfTermGrade]) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "EOTGrades")
		
		DispatchQueue.main.async {
			self.eotGrades = eotGrades
		}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredEndOfTermGrade.fetchRequest())
		
		do {
			try context.execute(deleteRequest)
		} catch {
			logger.error("Error executing request: \(error.localizedDescription)")
		}
		
		for eotGrade in eotGrades {
			_ = eotGrade.entity(context: context)
		}
		
		CoreDataModel.shared.saveContext()
	}
	
	/// Sets the app' tasks.
	/// - Parameter tasks: Received tasks
	public func setTasks(_ tasks: Vulcan.Tasks) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "Tasks")
		
		DispatchQueue.main.async {
			self.tasks = tasks
		}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		
		do {
			try context.execute(NSBatchDeleteRequest(fetchRequest: StoredHomework.fetchRequest()))
			try context.execute(NSBatchDeleteRequest(fetchRequest: StoredExam.fetchRequest()))
		} catch {
			logger.error("Error executing request: \(error.localizedDescription)")
		}
		
		for exam in tasks.exams {
			_ = exam.entity(context: context)
		}
		
		for homework in tasks.homework {
			_ = homework.entity(context: context)
		}
		
		CoreDataModel.shared.saveContext()
	}
	
	/// Sets the app' messages.
	/// - Parameters:
	///   - messages: Received messages with certain tag
	///   - tag: Tag of the messages
	public func setMessages(_ messages: [Vulcan.Message], tag: Vulcan.MessageTag) {
		let logger: Logger = Logger(subsystem: "VulcanStore", category: "Messages")
		
		DispatchQueue.main.async {
			switch tag {
				case .deleted:	break
				case .received:	self.receivedMessages = messages
				case .sent:		break
			}
		}
		
		let context = CoreDataModel.shared.persistentContainer.viewContext
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredMessage.fetchRequest())
		
		do {
			try context.execute(deleteRequest)
		} catch {
			logger.error("Error executing request: \(error.localizedDescription)")
		}
		
		for message in messages {
			_ = message.entity(context: context)
		}
		
		CoreDataModel.shared.saveContext()
	}
}

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
	private let ud = UserDefaults.group
	
	static let shared: VulcanStore = VulcanStore()
	
	/// Selected user
	@Published public private(set) var currentUser: Vulcan.Student?
	
	/// Data
	@Published public private(set) var schedule: [Vulcan.Schedule] = []
	@Published public private(set) var grades: [Vulcan.SubjectGrades] = []
	@Published public private(set) var eotGrades: [Vulcan.EndOfTermGrade] = []
	@Published public private(set) var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	@Published public private(set) var receivedMessages: [Vulcan.Message] = []
	
	private init() {
		// Load data
		let context = CoreDataModel.shared.persistentContainer.viewContext
		
		let dictionarySubjects: [DictionarySubject]? = try? context.fetch(DictionarySubject.fetchRequest()) as? [DictionarySubject]
		let dictionaryEmployees: [DictionaryEmployee]? = try? context.fetch(DictionaryEmployee.fetchRequest()) as? [DictionaryEmployee]
		
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
		if let storedGrades = try? context.fetch(StoredGrade.fetchRequest()) as? [StoredGrade] {
			let dictionary = Dictionary(grouping: storedGrades, by: \.subjectID)
			self.grades = dictionary
				.compactMap { subjectID, grades in
					guard let dictionarySubject: DictionarySubject = dictionarySubjects?.first(where: { $0.id == subjectID }),
						  let subjectName: String = dictionarySubject.name,
						  let subjectCode: String = dictionarySubject.code,
						  let dEmployeeID = grades.first?.dEmployeeID,
						  let dictionaryEmployee: DictionaryEmployee = dictionaryEmployees?.first(where: { $0.id == dEmployeeID }),
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
							var grade = Vulcan.Grade(from: grade)
							
							if let categoryID = grade.categoryID {
								let fetchRequest: NSFetchRequest<DictionaryGradeCategory> = DictionaryGradeCategory.fetchRequest()
								fetchRequest.predicate = NSPredicate(format: "id == %i", categoryID)
								
								if let dictionaryGradeCategories: [DictionaryGradeCategory] = try? context.fetch(fetchRequest) {
									grade.category = dictionaryGradeCategories.first(where: { $0.id == categoryID })
								}
							}
							
							return grade
						}
						.sorted { ($0.dateCreated, $0.entry ?? "") < ($1.dateCreated, $1.entry ?? "") }
						.filter { $0.subjectID == subject.id }
					
					return Vulcan.SubjectGrades(subject: subject, employee: employee, grades: grades)
				}
				.sorted { $0.subject.name < $1.subject.name }
		}
		
		// End of Term Grades
		if let storedEndOfTermGrades = try? context.fetch(StoredEndOfTermGrade.fetchRequest()) as? [StoredEndOfTermGrade] {
			self.eotGrades = storedEndOfTermGrades
				.compactMap { grade in
					var eotGrade = Vulcan.EndOfTermGrade(from: grade)
					eotGrade?.subject = dictionarySubjects?.first(where: { $0.id == grade.subjectID })
					
					return eotGrade
				}
				.sorted { ($0.subject?.name ?? "") < ($1.subject?.name ?? "") }
		}
		
		// Exams
		if let storedExams = try? context.fetch(StoredExam.fetchRequest()) as? [StoredExam] {
			self.tasks.exams = storedExams
				.compactMap { storedExam in
					guard let exam = Vulcan.Exam(from: storedExam) else {
						return nil
					}
					
					exam.subject = dictionarySubjects?.first(where: { $0.id == exam.subjectID })
					exam.employee = dictionaryEmployees?.first(where: { $0.id == exam.employeeID })
					
					return exam
				}
				.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
		}
		
		// Homework
		if let storedHomework = try? context.fetch(StoredHomework.fetchRequest()) as? [StoredHomework] {
			self.tasks.homework = storedHomework
				.compactMap { storedHomework in
					guard let homework = Vulcan.Homework(from: storedHomework) else {
						return nil
					}
					
					homework.subject = dictionarySubjects?.first(where: { $0.id == homework.subjectID })
					homework.employee = dictionaryEmployees?.first(where: { $0.id == homework.employeeID })
					
					return homework
				}
				.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
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
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "Users")
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
	
	/// Sets the store schedule.
	/// - Parameter schedule: Schedule received from the phone app
	public func setSchedule(_ schedule: [Vulcan.Schedule]) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "Schedule")
		
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
	
	/// Sets the store grades.
	/// - Parameter grades: Received grades
	public func setGrades(_ grades: [Vulcan.SubjectGrades]) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "Grades")
		
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
	
	/// Sets the store EOT grades.
	/// - Parameter eotGrades: End of term grades
	public func setEOTGrades(_ eotGrades: [Vulcan.EndOfTermGrade]) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "EOTGrades")
		
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
	
	/// Sets the store tasks.
	/// - Parameter tasks: Received tasks
	public func setTasks(_ tasks: Vulcan.Tasks) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "Tasks")
		
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
	
	/// Sets the store messages.
	/// - Parameters:
	///   - messages: Received messages with certain tag
	///   - tag: Tag of the messages
	public func setMessages(_ messages: [Vulcan.Message], tag: Vulcan.MessageTag) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).VulcanStore", category: "Messages")
		
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

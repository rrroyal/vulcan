//
//  Vulcan Models.swift
//  vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import SwiftUI

enum Vulcan {
	// MARK: - DictionaryType
	/// <#Description#>
	enum DictionaryType {
		case employees
		case gradeCategories
		case lessonTimes
		case noteCategories
		case presenceCategories
		case presenceTypes
		case subjects
		case teachers
	}
	
	// MARK: - Day
	/// <#Description#>
	struct Day: Identifiable, Codable {
		var id: Date
		var events: [Vulcan.Event]
	}
	
	// MARK: - Teacher
	/// Struct containing Teacher data and functions
	struct Teacher: Identifiable, Hashable, Codable {
		static func == (lhs: Vulcan.Teacher, rhs: Vulcan.Teacher) -> Bool {
			return lhs.id == rhs.id
		}
		
		/// <#Description#>
		/// - Parameters:
		///   - id: <#id description#>
		///   - name: <#name description#>
		///   - surname: <#surname description#>
		///   - code: <#code description#>
		///   - active: <#active description#>
		///   - teacher: <#teacher description#>
		///   - loginID: <#loginID description#>
		internal init(id: Int, name: String, surname: String, code: String, active: Bool, teacher: Bool, loginID: Int) {
			self.id = id
			self.name = name
			self.surname = surname
			self.code = code
			self.active = active
			self.teacher = teacher
			self.loginID = loginID
		}
		
		let id: Int
		let name: String
		let surname: String
		let code: String
		let active: Bool
		let teacher: Bool
		let loginID: Int
	}
	
	// MARK: - Lesson
	/// <#Description#>
	struct Lesson: Identifiable, Codable {
		let id: Int
		let number: Int
		let startTime: Int
		let endTime: Int
	}
	
	// MARK: - Grade
	/// <#Description#>
	struct Grade: Identifiable, Codable {
		internal init(id: Int, comment: String?, description: String, subjectID: Int, teacherID: Int, date: Date, weight: Double, value: Double?, categoryID: Int, weightModificator: Double, entry: String, position: Int, gradeWeight: Int, category: Vulcan.GradeCategory?) {
			self.id = id
			self.comment = comment
			self.subjectID = subjectID
			self.teacherID = teacherID
			self.date = date
			self.weight = weight
			self.value = value
			self.actualGrade = value ?? Double(entry) ?? 0
			self.categoryID = categoryID
			self.weightModificator = weightModificator
			self.entry = entry
			self.position = position
			self.gradeWeight = gradeWeight
			self.category = category
			
			if (description == "") {
				self.description = "NO_DESCRIPTION"
			} else {
				self.description = description
			}
		}
		
		let id: Int						// "Id"
		let comment: String?			// "Komentarz"
		let description: String			// "Opis"
		let subjectID: Int
		let teacherID: Int
		let date: Date					// Parse from "DataUtworzenia" (unix)
		let weight: Double				// "Waga"
		let value: Double?				// "Wartosc"
		let actualGrade: Double
		let categoryID: Int				// "IdKategoria"
		let weightModificator: Double	// "WagaModyfikatora"
		let entry: String				// "Wpis"
		let position: Int				// "Pozycja"
		let gradeWeight: Int			// "WagaOceny"
		let category: Vulcan.GradeCategory?
	}
	
	// MARK: - GradeCategory
	/// <#Description#>
	struct GradeCategory: Identifiable, Codable {
		let id: Int
		let code: String
		let name: String
	}
	
	// MARK: - TermGrades
	/// <#Description#>
	struct TermGrades: Codable {
		var count: Int {
			return self.anticipated.count + self.final.count
		}
		let anticipated: [EndOfTermGrade]
		let final: [EndOfTermGrade]
	}
	
	// MARK: - EndOfTermGrade
	/// <#Description#>
	struct EndOfTermGrade: Codable {
		let grade: Int
		let subject: Vulcan.Subject
	}
	
	// MARK: - Note
	/// <#Description#>
	struct Note: Identifiable, Codable {
		let id: Int			// "Id"
		let content: String	// "TrescUwagi"
		let date: Date		// Parsed from "DataWpisu"
		let userID: Int		// "IdUczen"
		let teacher: Vulcan.Teacher
		let category: Vulcan.NoteCategory
	}
	
	// MARK: - NoteCategory
	/// <#Description#>
	struct NoteCategory: Identifiable, Codable {
		let id: Int
		let name: String
		let active: Bool
	}
	
	// MARK: - PresenceCategory
	/// <#Description#>
	struct PresenceCategory: Identifiable {
		let id: Int
		let name: String
		let position: Int
		let present: Bool
		let exempt: Bool
		let late: Bool
		let justified: Bool
		let removed: Bool
	}
	
	// MARK: - PresenceType
	/// <#Description#>
	struct PresenceType: Identifiable {
		let id: Int
		let symbol: String
		let name: String
		let active: Bool
		let isDefault: Bool
		let category: Vulcan.PresenceCategory
	}
	
	// MARK: - Subject
	/// Struct containing subject data
	struct Subject: Identifiable, Hashable, Codable {
		static func == (lhs: Vulcan.Subject, rhs: Vulcan.Subject) -> Bool {
			return lhs.id == rhs.id
		}
		
		internal init(id: Int, name: String, code: String, active: Bool, position: Int, teacher: Vulcan.Teacher? = nil) {
			self.id = id
			self.name = name
			self.code = code
			self.active = active
			self.position = position
			self.teacher = teacher
		}
		
		let id: Int
		let name: String
		let code: String
		let active: Bool
		let position: Int
		let teacher: Teacher?
	}
	
	// MARK: - SubjectGrades
	/// <#Description#>
	struct SubjectGrades: Identifiable, Codable {
		var id: UUID = UUID()
		var subject: Vulcan.Subject
		var grades: [Vulcan.Grade]
	}
	
	// MARK: - User
	struct User: Identifiable, Equatable, Codable {
		var IdOkresKlasyfikacyjny: Int
		var OkresPoziom: Int
		var OkresNumer: Int
		var IdJednostkaSprawozdawcza: Int
		var JednostkaSprawozdawczaNazwa: String
		var JednostkaSprawozdawczaSymbol: String
		var IdJednostka: Int
		var JednostkaNazwa: String
		var JednostkaSkrot: String
		var OddzialSymbol: String
		var OddzialKod: String
		var UzytkownikRola: String
		var UzytkownikLogin: String
		var UzytkownikLoginId: Int
		var UzytkownikNazwa: String
		var id: Int
		var IdOddzial: Int
		var Imie: String
		var Imie2: String
		var Nazwisko: String
		var Pseudonim: String
		var UczenPlec: Int
		var Pozycja: Int
		var LoginId: Int?
	}
	
	// MARK: - Event
	/// Struct containing event (lesson) data
	struct Event: Identifiable, Codable {
		internal init(time: Int, dateStarts: Date, dateEnds: Date, lessonOfTheDay: Int, lesson: Vulcan.Lesson, subject: Vulcan.Subject, group: String?, room: String, teacher: Vulcan.Teacher, note: String, strikethrough: Bool, bold: Bool, userSchedule: Bool) {
			self.time = time
			self.date = Date(timeIntervalSince1970: TimeInterval(time))
			self.dateStarts = dateStarts
			self.dateEnds = dateEnds
			self.lessonOfTheDay = lessonOfTheDay
			self.lesson = lesson
			self.subject = subject
			self.group = group
			self.room = room
			self.teacher = teacher
			self.note = note
			self.strikethrough = strikethrough
			self.bold = bold
			self.userSchedule = userSchedule
			self.hasPassed = dateEnds < Date()
			self.actualGroup = Int(String(group?.prefix(1) ?? "0")) ?? 0
		}
		
		let id: UUID = UUID()
		let time: Int				// Dzien
		let date: Date				// Date from time
		let dateStarts: Date		// Parsed Date
		let dateEnds: Date			// Parsed Date
		let lessonOfTheDay: Int		// NumerLekcji
		let lesson: Vulcan.Lesson	// Parsed NumerLekcji
		let subject: Vulcan.Subject	// Parsed IdPrzedmiot
		let group: String?			// PodzialSkrot
		let actualGroup: Int		// Parsed from `group`
		let room: String			// Sala
		let teacher: Vulcan.Teacher	// Parsed IdPracownik
		let note: String			// AdnotacjaOZmianie
		let strikethrough: Bool		// PrzekreslonaNazwa
		let bold: Bool				// PogrubionaNazwa
		let userSchedule: Bool		// PlanUcznia
		var hasPassed: Bool			// dateEnds < Date()
	}
	
	// MARK: - Tasks
	struct Tasks: Hashable, Codable {
		var exams: [Vulcan.Task]
		var homework: [Vulcan.Task]
	}
	
	// MARK: - Task
	/// <#Description#>
	struct Task: Identifiable, Hashable, Codable {
		internal init(id: Int, subject: Vulcan.Subject, teacher: Vulcan.Teacher, departmentID: Int, groupID: Int?, groupName: String?, groupShortName: String?, typeID: Int, type: Bool, description: String, date: Date, tag: Vulcan.TaskTag) {
			self.id = id
			self.subject = subject
			self.teacher = teacher
			self.departmentID = departmentID
			self.groupID = groupID
			self.groupName = groupName
			self.groupShortName = groupShortName
			self.typeID = typeID
			self.type = type
			self.date = date
			self.tag = tag
			
			if (description == "") {
				self.description = "NO_DESCRIPTION"
			} else {
				self.description = description
			}
		}
		
		let id: Int
		let subject: Vulcan.Subject
		let teacher: Vulcan.Teacher
		let departmentID: Int
		let groupID: Int?
		let groupName: String?
		let groupShortName: String?
		let typeID: Int
		let type: Bool
		let description: String
		let date: Date
		let tag: Vulcan.TaskTag
	}
	
	// MARK: - Messages
	struct Messages: Hashable, Codable {
		var received: [Vulcan.Message]
		var sent: [Vulcan.Message]
		var deleted: [Vulcan.Message]
	}
	
	// MARK: - Message
	struct Message: Identifiable, Hashable, Codable {
		internal init(id: Int, senderID: Int, senders: [Vulcan.Teacher], recipients: [String]?, title: String, content: String, sentDate: Date, readDate: Date?, status: String, folder: String, hasBeenRead: Bool, tag: Vulcan.MessageTag) {
			self.id = id
			self.senderID = senderID
			self.senders = senders
			self.recipients = recipients
			self.title = title
			self.content = content
			self.sentDate = sentDate
			self.readDate = readDate
			self.status = status
			self.folder = folder
			self.hasBeenRead = hasBeenRead
			self.tag = tag
			
			var sendersParsedString: [String] = []
			for teacher in senders {
				sendersParsedString.append("\(teacher.name) \(teacher.surname)")
			}
			self.sendersString = sendersParsedString
		}
		
		let id: Int					// "WiadomoscId"
		let senderID: Int			// "NadawcaId"
		let senders: [Vulcan.Teacher]	// Parsed from "NadawcaId" or "Adresaci"
		let sendersString: [String]
		let recipients: [String]?	// "Adresaci"
		let title: String			// "Tytul"
		let content: String			// "Tresc"
		let sentDate: Date			// Parsed from "DataWyslaniaUnixEpoch"
		let readDate: Date?			// Parsed from "DataPrzeczytaniaUnixEpoch"
		let status: String			// "StatusWiadomosci"
		let folder: String			// "FolderWiadomosci"
		var hasBeenRead: Bool		// "Przeczytane"
		let tag: Vulcan.MessageTag
	}
		
	// MARK: - MessageTag
	enum MessageTag: String, Codable {
		case received = "Received"
		case deleted = "Deleted"
		case sent = "Sent"
	}
	
	// MARK: - MessageFolder
	enum MessageFolder: String {
		case read = "Widoczna"
		case deleted = "Usunieta"
	}
	
	// MARK: - TaskTag
	enum TaskTag: String, Codable {
		case exam = "Exams"
		case homework = "Homework"
	}
}

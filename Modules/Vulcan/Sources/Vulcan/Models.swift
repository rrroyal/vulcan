//
//  Models.swift
//  Vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import CoreData

#if canImport(EventKit)
import EventKit
#endif

public protocol VulcanTask {
	var id: Int { get }
	var dateEpoch: Int { get }
	var employeeID: Int { get }
	var subjectID: Int { get }
	var entry: String { get }
	
	var tag: Vulcan.TaskTag { get }
	var subject: DictionarySubject? { get set }
	var employee: DictionaryEmployee? { get set }
	
	var date: Date { get }
}

public extension Vulcan {
	// MARK: - Utils
	
	/// API request error
	enum APIError: Error, LocalizedError {
		case unknown
		case error(reason: String)
		
		public var errorDescription: String? {
			switch self {
				case .unknown:
					return "Unknown error"
				case .error (let reason):
					return reason
			}
		}
	}
	
	enum TaskTag: String {
		case exam = "TAG_EXAM"
		case homework = "TAG_HOMEWORK"
	}
	
	enum MessageTag: String {
		case received = "Received"
		case deleted = "Deleted"
		case sent = "Sent"
	}
	
	enum MessageFolder: String {
		case read = "Widoczna"
		case deleted = "Usunieta"
	}
	
	enum EndOfTermGradeType: Int, Comparable {
		public static func < (lhs: Vulcan.EndOfTermGradeType, rhs: Vulcan.EndOfTermGradeType) -> Bool {
			return lhs.rawValue < rhs.rawValue
		}
		
		case unknown = 0
		case expected = 1
		case final = 2
	}
	
	/// Message recipient
	class Recipient: NSObject, Identifiable, Codable {
		public init(id: Int, name: String) {
			self.id = id
			self.name = name
		}
		
		/// Initializes the entity from CoreData entity.
		/// - Parameter entity: CoreData entity
		public convenience init?(from entity: DictionaryEmployee) {
			var name: String = "Unknown employee"
			if let employeeName = entity.name,
			   let employeeSurname = entity.surname,
			   let employeeCode = entity.code {
				name = "\(employeeSurname) \(employeeName) (\(employeeCode))"
			}
			
			self.init(id: Int(entity.id), name: name)
		}
		
		enum CodingKeys: String, CodingKey {
			case name = "Nazwa"
			case id = "LoginId"
		}
		
		public let id: Int
		public let name: String
	}
	
	// MARK: - Misc.
	
	/// Struct containing the user data.
	struct Student: Identifiable, Codable, Equatable {
		public init(classificationPeriodID: Int, periodLevel: Int, periodNumber: Int, periodDateFrom: Int, periodDateTo: Int, reportingUnitID: Int, reportingUnitShort: String, reportingUnitName: String, reportingUnitSymbol: String, unitID: Int, unitName: String, unitShort: String, unitSymbol: String, unitCode: String, userRole: String, userLogin: String, userLoginID: Int, username: String, id: Int, branchID: Int, name: String, secondName: String, surname: String, nickname: String?, userGender: Int, position: Int, loginID: Int?) {
			self.classificationPeriodID = classificationPeriodID
			self.periodLevel = periodLevel
			self.periodNumber = periodNumber
			self.periodDateFrom = periodDateFrom
			self.periodDateTo = periodDateTo
			self.reportingUnitID = reportingUnitID
			self.reportingUnitShort = reportingUnitShort
			self.reportingUnitName = reportingUnitName
			self.reportingUnitSymbol = reportingUnitSymbol
			self.unitID = unitID
			self.unitName = unitName
			self.unitShort = unitShort
			self.unitSymbol = unitSymbol
			self.unitCode = unitCode
			self.userRole = userRole
			self.userLogin = userLogin
			self.userLoginID = userLoginID
			self.username = username
			self.id = id
			self.branchID = branchID
			self.name = name
			self.secondName = secondName
			self.surname = surname
			self.nickname = nickname
			self.userGender = userGender
			self.position = position
			self.loginID = loginID
		}
		
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init?(from entity: StoredStudent) {
			guard let reportingUnitShort = entity.reportingUnitShort,
				  let reportingUnitName = entity.reportingUnitName,
				  let reportingUnitSymbol = entity.reportingUnitSymbol,
				  let unitName = entity.unitName,
				  let unitShort = entity.unitShort,
				  let unitSymbol = entity.unitSymbol,
				  let unitCode = entity.unitCode,
				  let userRole = entity.userRole,
				  let userLogin = entity.userLogin,
				  let username = entity.username,
				  let name = entity.name,
				  let secondName = entity.secondName,
				  let surname = entity.surname
			else {
				return nil
			}
			
			self.init(classificationPeriodID: Int(entity.classificationPeriodID), periodLevel: Int(entity.periodLevel), periodNumber: Int(entity.periodNumber), periodDateFrom: Int(entity.periodDateFrom), periodDateTo: Int(entity.periodDateTo), reportingUnitID: Int(entity.reportingUnitID), reportingUnitShort: reportingUnitShort, reportingUnitName: reportingUnitName, reportingUnitSymbol: reportingUnitSymbol, unitID: Int(entity.unitID), unitName: unitName, unitShort: unitShort, unitSymbol: unitSymbol, unitCode: unitCode, userRole: userRole, userLogin: userLogin, userLoginID: Int(entity.userLoginID), username: username, id: Int(entity.id), branchID: Int(entity.branchID), name: name, secondName: secondName, surname: surname, nickname: entity.nickname, userGender: Int(entity.userGender), position: Int(entity.position), loginID: Int(entity.loginID))
		}
		
		enum CodingKeys: String, CodingKey {
			case classificationPeriodID = "IdOkresKlasyfikacyjny"
			case periodLevel = "OkresPoziom"
			case periodNumber = "OkresNumer"
			case periodDateFrom = "OkresDataOd"
			case periodDateTo = "OkresDataDo"
			case reportingUnitID = "IdJednostkaSprawozdawcza"
			case reportingUnitShort = "JednostkaSprawozdawczaSkrot"
			case reportingUnitName = "JednostkaSprawozdawczaNazwa"
			case reportingUnitSymbol = "JednostkaSprawozdawczaSymbol"
			case unitID = "IdJednostka"
			case unitName = "JednostkaNazwa"
			case unitShort = "JednostkaSkrot"
			case unitSymbol = "OddzialSymbol"
			case unitCode = "OddzialKod"
			case userRole = "UzytkownikRola"
			case userLogin = "UzytkownikLogin"
			case userLoginID = "UzytkownikLoginId"
			case username = "UzytkownikNazwa"
			case id = "Id"
			case branchID = "IdOddzial"
			case name = "Imie"
			case secondName = "Imie2"
			case surname = "Nazwisko"
			case nickname = "Pseudonim"
			case userGender = "UczenPlec"
			case position = "Pozycja"
			case loginID = "LoginId"
		}
		
		public let classificationPeriodID: Int
		public let periodLevel: Int
		public let periodNumber: Int
		public let periodDateFrom: Int
		public let periodDateTo: Int
		public let reportingUnitID: Int
		public let reportingUnitShort: String
		public let reportingUnitName: String
		public let reportingUnitSymbol: String
		public let unitID: Int
		public let unitName: String
		public let unitShort: String
		public let unitSymbol: String
		public let unitCode: String
		public let userRole: String
		public let userLogin: String
		public let userLoginID: Int
		public let username: String
		public let id: Int
		public let branchID: Int
		public let name: String
		public let secondName: String
		public let surname: String
		public let nickname: String?
		public let userGender: Int
		public let position: Int
		public let loginID: Int?
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredStudent {
			let entity: StoredStudent = StoredStudent(context: context)
			entity.branchID = Int32(self.branchID)
			entity.classificationPeriodID = Int32(self.classificationPeriodID)
			entity.id = Int64(self.id)
			entity.name = self.name
			entity.nickname = self.nickname
			entity.periodDateFrom = Int64(self.periodDateFrom)
			entity.periodDateTo = Int64(self.periodDateTo)
			entity.periodLevel = Int16(self.periodLevel)
			entity.periodNumber = Int16(self.periodNumber)
			entity.position = Int16(self.position)
			entity.reportingUnitID = Int16(self.reportingUnitID)
			entity.reportingUnitName = self.reportingUnitName
			entity.reportingUnitShort = self.reportingUnitShort
			entity.reportingUnitSymbol = self.reportingUnitSymbol
			entity.secondName = self.secondName
			entity.surname = self.surname
			entity.unitCode = self.unitCode
			entity.unitID = Int16(self.unitID)
			entity.unitName = self.unitName
			entity.unitShort = self.unitShort
			entity.unitSymbol = self.unitSymbol
			entity.userGender = Int16(self.userGender)
			entity.userLogin = self.userLogin
			entity.userLoginID = Int32(self.userLoginID)
			entity.userRole = self.userRole
			entity.username = self.username
			
			if let loginID = self.loginID { entity.loginID = Int32(loginID) }
			
			return entity
		}
	}
	
	/// Holds the grades of the defined subject.
	class SubjectGrades: Identifiable, Codable, Hashable {
		public init(subject: Vulcan.Subject, employee: Vulcan.Employee, grades: [Vulcan.Grade]) {
			self.subject = subject
			self.employee = employee
			self.grades = grades
		}
		
		public static func == (lhs: Vulcan.SubjectGrades, rhs: Vulcan.SubjectGrades) -> Bool {
			lhs.id == rhs.id &&
			lhs.subject.id == rhs.subject.id &&
			lhs.employee.id == rhs.employee.id &&
			lhs.grades == rhs.grades &&
			lhs.hasNewItems == rhs.hasNewItems
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(subject.id)
			hasher.combine(employee.id)
			hasher.combine(grades.map(\.entry))
		}
		
		public let subject: Vulcan.Subject
		public let employee: Vulcan.Employee
		public let grades: [Vulcan.Grade]
		public var hasNewItems: Bool = false
		
		public var id: Int {
			self.subject.id
		}
	}
	
	/// Holds the events for the date.
	struct Schedule: Identifiable, Codable, Hashable {
		public init(date: Date, events: [Vulcan.ScheduleEvent]) {
			self.date = date
			self.events = events
		}
		
		public let date: Date
		public let events: [Vulcan.ScheduleEvent]
		
		public var id: Int {
			Int(self.date.timeIntervalSince1970)
		}
	}
	
	/// Holds the various tasks, because of course vulcan couldn't merge these two.
	struct Tasks: Codable {
		public init(exams: [Vulcan.Exam], homework: [Vulcan.Homework]) {
			self.exams = exams
			self.homework = homework
		}
		
		public var exams: [Exam]
		public var homework: [Homework]
		
		public var combined: [VulcanTask] {
			return self.exams + self.homework
		}
	}
	
	// MARK: - Dictionary
	
	struct Employee: Identifiable, Codable, Hashable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case name = "Imie"
			case surname = "Nazwisko"
			case code = "Kod"
			case active = "Aktywny"
			case teacher = "Nauczyciel"
			case loginID = "LoginID"
		}
		
		public let id: Int
		public let name: String
		public let surname: String
		public let code: String
		public let active: Bool?
		public let teacher: Bool?
		public let loginID: Int?
	}
	
	struct Subject: Identifiable, Codable, Hashable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case name = "Nazwa"
			case code = "Kod"
			case active = "Aktywny"
			case position = "Pozycja"
		}
		
		public let id: Int
		public let name: String
		public let code: String
		public let active: Bool
		public let position: Int
	}
	
	struct LessonTime: Identifiable, Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case number = "Numer"
			case start = "Poczatek"
			case end = "Koniec"
		}
		
		public let id: Int
		public let number: Int
		public let start: Int
		public let end: Int
	}
	
	struct GradeCategory: Identifiable, Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case code = "Kod"
			case name = "Nazwa"
		}
		
		public let id: Int
		public let code: String
		public let name: String
	}
	
	struct NoteCategory: Identifiable, Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case name = "Nazwa"
			case active = "Aktywny"
		}
		
		public let id: Int
		public let name: String
		public let active: Bool
	}
	
	struct PresenceCategory: Identifiable, Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case name = "Nazwa"
			case position = "Pozycja"
			case present = "Obecnosc"
			case exempt = "Zwolnienie"
			case late = "Spoznienie"
			case justified = "Usprawiedliwione"
			case removed = "Usuniete"
		}
		
		public let id: Int
		public let name: String
		public let position: Int
		public let present: Bool
		public let exempt: Bool
		public let late: Bool
		public let justified: Bool
		public let removed: Bool
	}
	
	struct PresenceType: Identifiable, Codable {
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case symbol = "Symbol"
			case name = "Nazwa"
			case active = "Aktywny"
			case isDefault = "WpisDomyslny"
			case categoryID = "IdKategoriaFrek"
		}
		
		public let id: Int
		public let symbol: String
		public let name: String
		public let active: Bool
		public let isDefault: Bool
		public let categoryID: Int
	}
	
	// MARK: - API
	
	struct Presence {
		enum CodingKeys: String, CodingKey {
			case categoryID = "IdKategoria"
			case number = "Numer"
			case lessonTimeID = "IdPoraLekcji"
			case day = "Dzien"
			case subjectID = "IdPrzedmiot"
			case subjectName = "PrzedmiotNazwa"
		}
		
		public let categoryID: Int
		public let number: Int
		public let lessonTimeID: Int
		public let day: Int
		public let subjectID: Int
		public let subjectName: String
	}
	
	struct ScheduleEvent: Identifiable, Codable, Hashable {
		public init(dateEpoch: Int, lessonOfTheDay: Int, lessonTimeID: Int, subjectID: Int, subjectName: String, divisionShort: String?, room: String, employeeID: Int, helpingEmployeeID: Int?, oldEmployeeID: Int?, oldHelpingEmployeeID: Int?, scheduleID: Int, note: String?, labelStrikethrough: Bool, labelBold: Bool, isUserSchedule: Bool, dateStartsEpoch: TimeInterval? = nil, dateEndsEpoch: TimeInterval? = nil, employeeFullName: String? = nil) {
			self.dateEpoch = dateEpoch
			self.lessonOfTheDay = lessonOfTheDay
			self.lessonTimeID = lessonTimeID
			self.subjectID = subjectID
			self.subjectName = subjectName
			self.divisionShort = divisionShort
			self.room = room
			self.employeeID = employeeID
			self.helpingEmployeeID = helpingEmployeeID
			self.oldEmployeeID = oldEmployeeID
			self.oldHelpingEmployeeID = oldHelpingEmployeeID
			self.scheduleID = scheduleID
			self.note = note
			self.labelStrikethrough = labelStrikethrough
			self.labelBold = labelBold
			self.isUserSchedule = isUserSchedule
			self.dateStartsEpoch = dateStartsEpoch
			self.dateEndsEpoch = dateEndsEpoch
			self.employeeFullName = employeeFullName
		}
		
		/// Initializes the entity from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init?(from entity: StoredScheduleEvent) {
			guard let subjectName = entity.subjectName,
				  let room = entity.room else {
				return nil
			}
			
			self.init(dateEpoch: Int(entity.dateEpoch), lessonOfTheDay: Int(entity.lessonOfTheDay), lessonTimeID: Int(entity.lessonTimeID), subjectID: Int(entity.subjectID), subjectName: subjectName, divisionShort: entity.divisionShort, room: room, employeeID: Int(entity.employeeID), helpingEmployeeID: Int(entity.helpingEmployeeID), oldEmployeeID: Int(entity.oldEmployeeID), oldHelpingEmployeeID: Int(entity.oldHelpingEmployeeID), scheduleID: Int(entity.scheduleID), note: entity.note, labelStrikethrough: entity.labelStrikethrough, labelBold: entity.labelBold, isUserSchedule: entity.isUserSchedule, dateStartsEpoch: TimeInterval(entity.dateStartsEpoch), dateEndsEpoch: TimeInterval(entity.dateEndsEpoch), employeeFullName: entity.employeeFullName)
		}
		
		enum CodingKeys: String, CodingKey {
			case dateEpoch = "Dzien"
			case lessonOfTheDay = "NumerLekcji"
			case lessonTimeID = "IdPoraLekcji"
			case subjectID = "IdPrzedmiot"
			case subjectName = "PrzedmiotNazwa"
			case divisionShort = "PodzialSkrot"
			case room = "Sala"
			case employeeID = "IdPracownik"
			case helpingEmployeeID = "IdPracownikWspomagajacy"
			case oldEmployeeID = "IdPracownikOld"
			case oldHelpingEmployeeID = "IdPracownikWspomagajacyOld"
			case scheduleID = "IdPlanLekcji"
			case note = "AdnotacjaOZmianie"
			case labelStrikethrough = "PrzekreslonaNazwa"
			case labelBold = "PogrubionaNazwa"
			case isUserSchedule = "PlanUcznia"
			case dateStartsEpoch = "GodzinaRozpoczecia"
			case dateEndsEpoch = "GodzinaZakonczenia"
			case employeeFullName = "PracownikPelnaNazwa"
		}
		
		public let dateEpoch: Int
		public let lessonOfTheDay: Int
		public let lessonTimeID: Int
		public let subjectID: Int
		public let subjectName: String
		public let divisionShort: String?
		public let room: String
		public let employeeID: Int
		public let helpingEmployeeID: Int?
		public let oldEmployeeID: Int?
		public let oldHelpingEmployeeID: Int?
		public let scheduleID: Int
		public let note: String?
		public let labelStrikethrough: Bool
		public let labelBold: Bool
		public let isUserSchedule: Bool
		
		public var dateStartsEpoch: TimeInterval?
		public var dateEndsEpoch: TimeInterval?
		public var employeeFullName: String?
		
		public var subject: DictionarySubject?
		public var employee: DictionaryEmployee?
		
		public var id: String {
			"\(self.dateEpoch):\(self.lessonOfTheDay):\(self.lessonTimeID):\(self.subjectID):\(self.divisionShort ?? "ungrouped")"
		}
		
		public var date: Date { Date(timeIntervalSince1970: TimeInterval(self.dateEpoch)) }
		
		public var dateStarts: Date? {
			guard let epoch = self.dateStartsEpoch else {
				return nil
			}
			
			return Date(timeIntervalSince1970: TimeInterval(epoch))
		}
		
		public var dateEnds: Date? {
			guard let epoch = self.dateEndsEpoch else {
				return nil
			}
			
			return Date(timeIntervalSince1970: TimeInterval(epoch))
		}
		
		public var isCurrent: Bool? {
			get {
				guard let dateStarts = dateStarts,
					  let dateEnds = dateEnds else {
					return nil
				}
				
				let now: Date = Date()
				return now > dateStarts && now < dateEnds
			}
		}
		
		public var group: Int? {
			guard let division = self.divisionShort,
				  let firstCharacter = division.first else {
				return nil
			}
			
			return Int(String(firstCharacter))
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredScheduleEvent {
			let entity: StoredScheduleEvent = StoredScheduleEvent(context: context)
			entity.dateEpoch = Int64(self.dateEpoch)
			entity.labelBold = self.labelBold
			entity.labelStrikethrough = self.labelStrikethrough
			entity.lessonOfTheDay = Int16(self.lessonOfTheDay)
			entity.lessonTimeID = Int16(self.lessonTimeID)
			entity.note = self.note
			entity.room = self.room
			entity.subjectID = Int32(self.subjectID)
			entity.subjectName = self.subjectName
			entity.employeeID = Int32(self.employeeID)
			entity.isUserSchedule = self.isUserSchedule
			entity.divisionShort = self.divisionShort
			entity.id = self.id
			
			if let dateStartsEpoch = self.dateStartsEpoch { entity.dateStartsEpoch = Int64(dateStartsEpoch) }
			if let dateEndsEpoch = self.dateEndsEpoch { entity.dateEndsEpoch = Int64(dateEndsEpoch) }
			if let oldEmployeeID = self.oldEmployeeID { entity.oldEmployeeID = Int32(oldEmployeeID) }
			if let helpingEmployeeID = self.helpingEmployeeID { entity.helpingEmployeeID = Int32(helpingEmployeeID) }
			if let oldHelpingEmployeeID = self.oldHelpingEmployeeID { entity.oldHelpingEmployeeID = Int32(oldHelpingEmployeeID) }
			if let employeeName = self.employee?.name,
			   let employeeSurname = self.employee?.surname {
				entity.employeeFullName = "\(employeeName) \(employeeSurname)"
			} else if let employeeFullName = self.employeeFullName {
				entity.employeeFullName = employeeFullName
			}
			
			return entity
		}
	}
	
	struct Grade: Identifiable, Codable, Hashable, Equatable {
		public init(id: Int, position: Int, subjectPosition: Int, subjectID: Int, categoryID: Int?, entry: String?, value: Double?, modifierWeight: Double?, gradeWeight: Double?, counter: Double?, denominator: Double?, comment: String?, weight: String?, description: String?, dateCreatedEpoch: Int, dateModifiedEpoch: Int?, dEmployeeID: Int, mEmployeeID: Int?) {
			self.id = id
			self.position = position
			self.subjectPosition = subjectPosition
			self.subjectID = subjectID
			self.categoryID = categoryID
			self.entry = entry
			self.value = value
			self.modifierWeight = modifierWeight
			self.gradeWeight = gradeWeight
			self.counter = counter
			self.denominator = denominator
			self.comment = comment
			self.weight = weight
			self.description = description
			self.dateCreatedEpoch = dateCreatedEpoch
			self.dateModifiedEpoch = dateModifiedEpoch
			self.dEmployeeID = dEmployeeID
			self.mEmployeeID = mEmployeeID
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init(from entity: StoredGrade) {
			self.init(id: Int(entity.id), position: Int(entity.position), subjectPosition: Int(entity.subjectPosition), subjectID: Int(entity.subjectID), categoryID: Int(entity.categoryID), entry: entity.entry, value: Double(entity.value), modifierWeight: Double(entity.modifierWeight), gradeWeight: Double(entity.gradeWeight), counter: Double(entity.counter), denominator: Double(entity.denominator), comment: entity.comment, weight: entity.weight, description: entity.gradeDescription, dateCreatedEpoch: Int(entity.dateCreatedEpoch), dateModifiedEpoch: Int(entity.dateModifiedEpoch), dEmployeeID: Int(entity.dEmployeeID), mEmployeeID: Int(entity.mEmployeeID))
		}
		
		public static func == (lhs: Vulcan.Grade, rhs: Vulcan.Grade) -> Bool {
			lhs.entry == rhs.entry &&
			lhs.categoryID == rhs.categoryID &&
			lhs.dateCreatedEpoch == rhs.dateCreatedEpoch &&
			lhs.dateModifiedEpoch == rhs.dateModifiedEpoch &&
			lhs.weight == rhs.weight
		}
		
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case position = "Pozycja"
			case subjectPosition = "PrzedmiotPozycja"
			case subjectID = "IdPrzedmiot"
			case categoryID = "IdKategoria"
			case entry = "Wpis"
			case value = "Wartosc"
			case modifierWeight = "WagaModyfikatora"
			case gradeWeight = "WagaOceny"
			case counter = "Licznik"
			case denominator = "Mianownik"
			case comment = "Komentarz"
			case weight = "Waga"
			case description = "Opis"
			case dateCreatedEpoch = "DataUtworzenia"
			case dateModifiedEpoch = "DataModyfikacji"
			case dEmployeeID = "IdPracownikD"
			case mEmployeeID = "IdPracownikM"
		}
		
		public let id: Int
		public let position: Int
		public let subjectPosition: Int
		public let subjectID: Int
		public let categoryID: Int?
		public let entry: String?
		public let value: Double?
		public let modifierWeight: Double?
		public let gradeWeight: Double?
		public let counter: Double?
		public let denominator: Double?
		public let comment: String?
		public let weight: String?
		public let description: String?
		public let dateCreatedEpoch: Int
		public let dateModifiedEpoch: Int?
		public let dEmployeeID: Int
		public let mEmployeeID: Int?
		
		public var category: DictionaryGradeCategory?
		
		public var dateCreated: Date { Date(timeIntervalSince1970: TimeInterval(self.dateCreatedEpoch)) }
		
		public var grade: Int? {
			guard let entry = self.entry else {
				return nil
			}
			
			return Int(entry.westernArabicNumeralsOnly)
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredGrade {
			let entity: StoredGrade = StoredGrade(context: context)
			entity.comment = self.comment
			entity.subjectID = Int32(self.subjectID)
			entity.dEmployeeID = Int32(self.dEmployeeID)
			entity.dateCreatedEpoch = Int64(self.dateCreatedEpoch)
			entity.entry = self.entry
			entity.gradeDescription = self.description
			entity.id = Int64(self.id)
			entity.position = Int16(self.position)
			entity.weight = self.weight
			
			if let value = self.categoryID { entity.categoryID = Int32(value) }
			if let value = self.counter { entity.counter = Float(value) }
			if let value = self.dateModifiedEpoch { entity.dateModifiedEpoch = Int64(value) }
			if let value = self.gradeWeight { entity.gradeWeight = Float(value) }
			if let value = self.denominator { entity.denominator = Float(value) }
			if let value = self.mEmployeeID { entity.mEmployeeID = Int32(value) }
			if let value = self.modifierWeight { entity.modifierWeight = Float(value) }
			
			return entity
		}
	}
	
	struct EndOfTermGrade: Identifiable, Codable {
		public init(subjectID: Int, entry: String, subject: DictionarySubject? = nil, type: EndOfTermGradeType? = .unknown) {
			self.subjectID = subjectID
			self.entry = entry
			self.subject = subject
			self.type = type
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init?(from entity: StoredEndOfTermGrade) {
			guard let entry = entity.entry else {
				return nil
			}
			
			self.init(subjectID: Int(entity.subjectID), entry: entry, type: EndOfTermGradeType(rawValue: Int(entity.type)))
		}
		
		enum CodingKeys: String, CodingKey {
			case subjectID = "IdPrzedmiot"
			case entry = "Wpis"
		}
		
		public let subjectID: Int
		public let entry: String
		
		public var subject: DictionarySubject?
		public var type: EndOfTermGradeType?
		
		public var id: Int {
			self.subjectID
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredEndOfTermGrade {
			let entity: StoredEndOfTermGrade = StoredEndOfTermGrade(context: context)
			entity.entry = self.entry
			entity.subjectID = Int32(self.subjectID)
			entity.type = Int16(self.type?.rawValue ?? 0)
			
			return entity
		}
	}
	
	struct EndOfTermPoints: Identifiable, Codable {
		public init(subjectID: Int, gradeAverage: String, points: String) {
			self.subjectID = subjectID
			self.gradeAverage = gradeAverage
			self.points = points
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init?(from entity: StoredEndOfTermPoints) {
			guard let gradeAverage = entity.gradeAverage,
				  let points = entity.points
			else {
				return nil
			}
			
			self.init(subjectID: Int(entity.subjectID), gradeAverage: gradeAverage, points: points)
		}
		
		enum CodingKeys: String, CodingKey {
			case subjectID = "IdPrzedmiot"
			case gradeAverage = "SredniaOcen"
			case points = "SumaPunktow"
		}
		
		public let subjectID: Int
		public let gradeAverage: String
		public let points: String
		
		public var id: Int {
			self.subjectID
		}
		
		public var grade: Double? {
			Double(self.gradeAverage)
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredEndOfTermPoints {
			let entity: StoredEndOfTermPoints = StoredEndOfTermPoints(context: context)
			entity.subjectID = Int32(self.subjectID)
			entity.gradeAverage = self.gradeAverage
			entity.points = self.points
			
			return entity
		}
	}
	
	class Exam: Identifiable, Codable, VulcanTask {
		public init(id: Int, subjectID: Int, employeeID: Int, branchID: Int, divisionID: Int?, divisionName: String?, divisionShort: String?, isBigType: Bool, entry: String, dateEpoch: Int, subject: DictionarySubject? = nil, employee: DictionaryEmployee? = nil) {
			self.id = id
			self.subjectID = subjectID
			self.employeeID = employeeID
			self.branchID = branchID
			self.divisionID = divisionID
			self.divisionName = divisionName
			self.divisionShort = divisionShort
			self.isBigType = isBigType
			self.entry = entry
			self.dateEpoch = dateEpoch
			self.subject = subject
			self.employee = employee
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public convenience init?(from entity: StoredExam) {
			guard let entry = entity.entry else {
				return nil
			}
			
			self.init(id: Int(entity.id), subjectID: Int(entity.subjectID), employeeID: Int(entity.employeeID), branchID: Int(entity.branchID), divisionID: Int(entity.divisionID), divisionName: entity.divisionName, divisionShort: entity.divisionShort, isBigType: entity.isBigType, entry: entry, dateEpoch: Int(entity.dateEpoch))
		}
		
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case subjectID = "IdPrzedmiot"
			case employeeID = "IdPracownik"
			case branchID = "IdOddzial"
			case divisionID = "IdPodzial"
			case divisionName = "PodzialNazwa"
			case divisionShort = "PodzialSkrot"
			case isBigType = "Rodzaj"
			case entry = "Opis"
			case dateEpoch = "Data"
		}
		
		public let id: Int
		public let subjectID: Int
		public let employeeID: Int
		public let branchID: Int
		public let divisionID: Int?
		public let divisionName: String?
		public let divisionShort: String?
		public let isBigType: Bool
		public let entry: String
		public let dateEpoch: Int
		
		public let tag: Vulcan.TaskTag = .exam
		
		public var subject: DictionarySubject?
		public var employee: DictionaryEmployee?
		
		public var date: Date {
			Date(timeIntervalSince1970: TimeInterval(self.dateEpoch))
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredExam {
			let entity: StoredExam = StoredExam(context: context)
			entity.id = Int64(self.id)
			entity.subjectID = Int32(self.subjectID)
			entity.employeeID = Int32(self.employeeID)
			entity.branchID = Int32(self.branchID)
			entity.divisionName = self.divisionName
			entity.divisionShort = self.divisionShort
			entity.isBigType = self.isBigType
			entity.entry = self.entry
			entity.dateEpoch = Int64(self.dateEpoch)
			
			if let divisionID = self.divisionID {
				entity.divisionID = Int16(divisionID)
			}
			
			return entity
		}		
	}
	
	class Homework: Identifiable, Codable, VulcanTask {
		public init(id: Int, studentID: Int, dateEpoch: Int, employeeID: Int, subjectID: Int, entry: String, subject: DictionarySubject? = nil, employee: DictionaryEmployee? = nil) {
			self.id = id
			self.studentID = studentID
			self.dateEpoch = dateEpoch
			self.employeeID = employeeID
			self.subjectID = subjectID
			self.entry = entry
			self.subject = subject
			self.employee = employee
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public convenience init?(from entity: StoredHomework) {
			guard let entry = entity.entry else {
				return nil
			}
			
			self.init(id: Int(entity.id), studentID: Int(entity.studentID), dateEpoch: Int(entity.dateEpoch), employeeID: Int(entity.employeeID), subjectID: Int(entity.subjectID), entry: entry)
		}
		
		enum CodingKeys: String, CodingKey {
			case id = "Id"
			case studentID = "IdUczen"
			case dateEpoch = "Data"
			case employeeID = "IdPracownik"
			case subjectID = "IdPrzedmiot"
			case entry = "Opis"
		}
		
		public var id: Int
		public let studentID: Int
		public let dateEpoch: Int
		public let employeeID: Int
		public let subjectID: Int
		public let entry: String
		
		public let tag: Vulcan.TaskTag = .homework
		
		public var subject: DictionarySubject?
		public var employee: DictionaryEmployee?
		
		public var date: Date {
			Date(timeIntervalSince1970: TimeInterval(self.dateEpoch))
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredHomework {
			let entity: StoredHomework = StoredHomework(context: context)
			entity.id = Int64(self.id)
			entity.studentID = Int32(self.studentID)
			entity.dateEpoch = Int64(self.dateEpoch)
			entity.employeeID = Int32(self.employeeID)
			entity.subjectID = Int32(self.subjectID)
			entity.entry = self.entry
			
			return entity
		}
	}
	
	struct Note: Identifiable, Codable {
		public init(employeeID: Int, studentName: String, studentSurname: String, employeeName: String, employeeSurname: String, dateCreatedEpoch: Int, dateModifiedEpoch: Int?, key: String, id: Int, entry: String, studentID: Int, categoryID: Int) {
			self.employeeID = employeeID
			self.studentName = studentName
			self.studentSurname = studentSurname
			self.employeeName = employeeName
			self.employeeSurname = employeeSurname
			self.dateCreatedEpoch = dateCreatedEpoch
			self.dateModifiedEpoch = dateModifiedEpoch
			self.key = key
			self.id = id
			self.entry = entry
			self.studentID = studentID
			self.categoryID = categoryID
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public init?(from entity: StoredNote) {
			guard let studentName = entity.studentName,
				  let studentSurname = entity.studentSurname,
				  let employeeName = entity.employeeName,
				  let employeeSurname = entity.employeeSurname,
				  let key = entity.key,
				  let entry = entity.entry else {
				return nil
			}
			
			self.init(employeeID: Int(entity.employeeID), studentName: studentName, studentSurname: studentSurname, employeeName: employeeName, employeeSurname: employeeSurname, dateCreatedEpoch: Int(entity.dateCreatedEpoch), dateModifiedEpoch: Int(entity.dateModifiedEpoch), key: key, id: Int(entity.id), entry: entry, studentID: Int(entity.studentID), categoryID: Int(entity.categoryID))
		}
		
		enum CodingKeys: String, CodingKey {
			case key = "UwagaKey"
			case id = "Id"
			case categoryID = "IdKategoriaUwag"
			case dateCreatedEpoch = "DataWpisu"
			case dateModifiedEpoch = "DataModyfikacji"
			case studentID = "IdUczen"
			case entry = "TrescUwagi"
			case employeeName = "PracownikImie"
			case employeeSurname = "PracownikNazwisko"
			case studentName = "UczenImie"
			case studentSurname = "UczenNazwisko"
			case employeeID = "IdPracownik"
		}
		
		public let key: String
		public let id: Int
		public let categoryID: Int?
		public let dateCreatedEpoch: Int
		public let dateModifiedEpoch: Int?
		public let studentID: Int
		public let entry: String
		public let employeeName: String
		public let employeeSurname: String
		public let studentName: String
		public let studentSurname: String
		public let employeeID: Int
		
		public var employee: DictionaryEmployee?
		public var category: DictionaryNoteCategory?
		
		public var date: Date {
			Date(timeIntervalSince1970: TimeInterval(self.dateCreatedEpoch))
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredNote {
			let entity: StoredNote = StoredNote(context: context)
			entity.entry = self.entry
			entity.dateCreatedEpoch = Int64(self.dateCreatedEpoch)
			entity.id = Int64(self.id)
			entity.key = self.key
			entity.employeeID = Int32(self.employeeID)
			entity.employeeName = self.employeeName
			entity.employeeSurname = self.employeeSurname
			entity.studentID = Int32(self.studentID)
			entity.studentName = self.studentName
			entity.studentSurname = self.studentSurname
			
			if let categoryID = self.categoryID {
				entity.categoryID = Int32(categoryID)
			}
			
			if let dateModified = self.dateModifiedEpoch {
				entity.dateModifiedEpoch = Int64(dateModified)
			}
			
			return entity
		}
	}
	
	class Message: Identifiable, Codable, Hashable {
		public init(id: Int, sender: String?, senderID: Int, recipients: [Vulcan.Recipient]?, title: String, content: String, dateSentEpoch: Int, dateReadEpoch: Int?, status: String, folder: String, read: String?, tag: Vulcan.MessageTag? = nil) {
			self.id = id
			self.sender = sender
			self.senderID = senderID
			self.recipients = recipients
			self.title = title
			self.content = content
			self.dateSentEpoch = dateSentEpoch
			self.dateReadEpoch = dateReadEpoch
			self.status = status
			self.folder = folder
			self.read = read
			self.tag = tag
		}
		
		/// Initializes the object from CoreData entity.
		/// - Parameter entity: CoreData entity
		public convenience init?(from entity: StoredMessage) {
			guard let title = entity.title,
				  let content = entity.content,
				  let status = entity.status,
				  let folder = entity.folder else {
				return nil
			}
			
			var recipients: [Vulcan.Recipient]?
			if let entityRecipients = entity.recipients {
				let decoder: JSONDecoder = JSONDecoder()
				recipients = try? decoder.decode([Vulcan.Recipient].self, from: entityRecipients)
			}
			
			self.init(id: Int(entity.id), sender: entity.sender, senderID: Int(entity.senderID), recipients: recipients, title: title, content: content, dateSentEpoch: Int(entity.dateSentEpoch), dateReadEpoch: Int(entity.dateReadEpoch), status: status, folder: folder, read: entity.read, tag: nil)
		}
		
		enum CodingKeys: String, CodingKey {
			case id = "WiadomoscId"
			case sender = "Nadawca"
			case senderID = "NadawcaId"
			case recipients = "Adresaci"
			case title = "Tytul"
			case content = "Tresc"
			case dateSentEpoch = "DataWyslaniaUnixEpoch"
			case dateReadEpoch = "DataPrzeczytaniaUnixEpoch"
			case status = "StatusWiadomosci"
			case folder = "FolderWiadomosci"
			case read = "Przeczytane"
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		
		public static func == (lhs: Vulcan.Message, rhs: Vulcan.Message) -> Bool {
			lhs.id == rhs.id &&
			lhs.dateSentEpoch == rhs.dateSentEpoch &&
			lhs.senderID == rhs.senderID &&
			lhs.title == rhs.title &&
			lhs.content == rhs.content &&
			lhs.read == rhs.read
		}
		
		public let id: Int
		public let sender: String?
		public let senderID: Int
		public let recipients: [Vulcan.Recipient]?
		public let title: String
		public let content: String
		public let dateSentEpoch: Int
		public var dateReadEpoch: Int?
		public let status: String
		public var folder: String
		public var read: String?	// Int?
		
		public var tag: Vulcan.MessageTag?
		
		public var dateSent: Date {
			Date(timeIntervalSince1970: TimeInterval(self.dateSentEpoch))
		}
		
		public var dateRead: Date? {
			get {
				guard let date = dateReadEpoch else {
					return nil
				}
				
				return Date(timeIntervalSince1970: TimeInterval(date))
			}
			
			set(value) {
				if let timeInterval = value?.timeIntervalSince1970 {
					self.dateReadEpoch = Int(timeInterval)
				}
			}
		}
		
		public var hasBeenRead: Bool {
			get {
				switch self.read ?? "" {
					case "0":	return false
					case "1":	return true
					default:	break
				}
				
				switch self.dateRead {
					case nil:	return false
					default:	return true
				}
			}
			
			set(value) {
				self.read = "1"
				self.dateRead = Date()
			}
		}
		
		public var recipientsString: [String] {
			guard let recipients = self.recipients else {
				return []
			}
			
			return recipients.map(\.name) 
		}
		
		/// Returns the CoreData entity.
		/// - Parameter context: Context to insert into
		/// - Returns: CoreData entity
		public func entity(context: NSManagedObjectContext) -> StoredMessage {
			let entity: StoredMessage = StoredMessage(context: context)
			entity.content = self.content
			entity.dateSentEpoch = Int64(self.dateSentEpoch)
			entity.folder = self.folder
			entity.id = Int64(self.id)
			entity.read = self.read
			entity.sender = self.sender
			entity.senderID = Int32(self.senderID)
			entity.status = self.status
			entity.title = self.title
			
			if let recipients = self.recipients {
				let data = try? JSONEncoder().encode(recipients)
				entity.recipients = data
			}
			
			
			if let dateReadEpoch = self.dateReadEpoch {
				entity.dateReadEpoch = Int64(dateReadEpoch)
			}
			
			return entity
		}
	}
}

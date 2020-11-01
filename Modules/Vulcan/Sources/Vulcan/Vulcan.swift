//
//  Vulcan.swift
//  Vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Combine
import CoreData
import os
import UserNotifications
import KeychainAccess
import Network

#if canImport(WidgetKit)
import WidgetKit
#endif

@available (iOS 14, macOS 10.16, watchOS 7, tvOS 14, *)
/// Model that manages all of the Vulcan-related data.
public final class Vulcan: ObservableObject {
	static public let shared: Vulcan = Vulcan()
	
	// MARK: - Private variables
	
	private let keychain: Keychain = Keychain(service: ("\(Bundle.main.bundleIdentifier ?? "vulcan")-\(Bundle.main.deviceName)")).label("vulcan Certificate (\(Bundle.main.deviceName))").synchronizable(false).accessibility(.afterFirstUnlock)
	private let ud = UserDefaults.group
	private let persistentContainer: NSPersistentContainer = CoreDataModel.shared.persistentContainer
	private let monitor: NWPathMonitor = NWPathMonitor()
	
	private var cancellableSet: Set<AnyCancellable> = []
	
	private var endpointURL: String? {
		get { return self.keychain["endpointURL"] }
		set (value) { self.keychain["endpointURL"] = value }
	}
	
	/// Used to manage the current data state.
	public struct DataState {
		fileprivate init(dictionary: Vulcan.DataState.Status = DataState.Status(), users: Vulcan.DataState.Status = DataState.Status(), schedule: Vulcan.DataState.Status = DataState.Status(), grades: Vulcan.DataState.Status = DataState.Status(), eotGrades: Vulcan.DataState.Status = DataState.Status()) {
			self.dictionary = dictionary
			self.users = users
			self.schedule = schedule
			self.grades = grades
			self.eotGrades = eotGrades
		}
		
		public struct Status {
			fileprivate init(loading: Bool = false, lastFetched: Date? = nil, progress: Double? = nil) {
				self.loading = loading
				self.lastFetched = lastFetched
				self.progress = progress
			}
			
			public var loading: Bool = false
			public var lastFetched: Date?
			public var progress: Double?
			
			public var fetched: Bool {
				return self.lastFetched != nil
			}
		}
		
		public var dictionary: DataState.Status = .init()
		public var users: DataState.Status = .init()
		
		public var schedule: DataState.Status = .init()
		public var grades: DataState.Status = .init()
		public var eotGrades: DataState.Status = .init()
		public var notes: DataState.Status = .init()
		public var tasks: DataState.Status = .init()
		public var messages: [Vulcan.MessageTag: DataState.Status] = [
			.deleted:	.init(),
			.received:	.init(),
			.sent:		.init()
		]
	}
	
	// MARK: - Public variables
	
	/// Notifiers
	@Published public private(set) var scheduleDidChange: PassthroughSubject = PassthroughSubject<Bool, Never>()
	
	/// Data state
	@Published public private(set) var dataState: DataState = DataState()
	
	/// Selected user
	@Published public private(set) var currentUser: Vulcan.Student?
	
	/// Data
	@Published public private(set) var users: [Vulcan.Student] = []
	@Published public private(set) var schedule: [Vulcan.Schedule] = []
	@Published public private(set) var grades: [Vulcan.SubjectGrades] = []
	@Published public private(set) var eotGrades: [Vulcan.EndOfTermGrade] = []
	@Published public private(set) var notes: [Vulcan.Note] = []
	@Published public private(set) var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	@Published public private(set) var messages: [Vulcan.MessageTag: [Vulcan.Message]] = [:]
	
	// MARK: - init
	/// Initializes, loads and sanity checks the data.
	private init() {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Init")
		monitor.start(queue: .global(qos: .utility))
		
		// If we have the certificate, we're logged in
		if (self.keychain["CertificatePfx"] != nil) && (self.keychain["CertificatePfx"] != "") {
			logger.debug("Logged in. Key: \(self.keychain["CertificateKey"] ?? "none", privacy: .private).")
		} else {
			logger.debug("Not logged in.")
			self.logOut()
			return
		}
		
		// Load cached data
		logger.info("Loading stored data...")
		let context = self.persistentContainer.viewContext
		
		let studentFetchRequest: NSFetchRequest = StoredStudent.fetchRequest()
		studentFetchRequest.predicate = NSPredicate(format: "id == %d", ud.integer(forKey: UserDefaults.AppKeys.userID.rawValue))
		if let storedStudents: [StoredStudent] = try? context.fetch(studentFetchRequest),
		   let storedStudent: StoredStudent = storedStudents.first {
			self.currentUser = Vulcan.Student(from: storedStudent)
		}
		
		if let dictionarySubjects: [DictionarySubject] = try? context.fetch(DictionarySubject.fetchRequest()),
		   let dictionaryEmployees: [DictionaryEmployee] = try? context.fetch(DictionaryEmployee.fetchRequest()) {
			// Schedule
			if let storedSchedule = try? context.fetch(StoredScheduleEvent.fetchRequest()) as? [StoredScheduleEvent] {
				self.schedule = storedSchedule.grouped
					.map { date, storedEvents in
						let events: [Vulcan.ScheduleEvent] = storedEvents
							.compactMap { entity in
								guard var event = ScheduleEvent(from: entity) else {
									return nil
								}
								
								if let subject: DictionarySubject = dictionarySubjects.first(where: { $0.id == event.subjectID }) {
									event.subject = subject
								}
								
								if let employee: DictionaryEmployee = dictionaryEmployees.first(where: { $0.id == event.employeeID }),
								   let employeeName = employee.name,
								   let employeeSurname = employee.surname {
									event.employee = employee
									event.employeeFullName = "\(employeeName) \(employeeSurname)"
								}
								
								if let dictionaryLessonTimes: [DictionaryLessonTime] = try? context.fetch(DictionaryLessonTime.fetchRequest()),
								   let lessonTime: DictionaryLessonTime = dictionaryLessonTimes.first(where: { $0.id == event.lessonTimeID }) {
									event.dateStartsEpoch = TimeInterval(event.dateEpoch + Int(lessonTime.start) + 3600)
									event.dateEndsEpoch = TimeInterval(event.dateEpoch + Int(lessonTime.end) + 3600)
								}
								
								return event
							}
							.sorted { $0.lessonOfTheDay < $1.lessonOfTheDay }
						
						return Schedule(date: date, events: events)
					}
					.sorted { $0.date < $1.date }
			}
			
			// Grades
			if let storedGrades = try? context.fetch(StoredGrade.fetchRequest()) as? [StoredGrade] {
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
						var eotGrade = EndOfTermGrade(from: grade)
						eotGrade?.subject = dictionarySubjects.first(where: { $0.id == grade.subjectID })
						
						return eotGrade
					}
					.sorted { ($0.subject?.name ?? "") < ($1.subject?.name ?? "") }
			}
			
			// Notes
			if let storedNotes = try? context.fetch(StoredNote.fetchRequest()) as? [StoredNote] {
				self.notes = storedNotes
					.compactMap { note in
						guard var note = Note(from: note) else {
							return nil
						}
						
						note.employee = dictionaryEmployees.first(where: { $0.id == note.employeeID })
						
						if let categoryID = note.categoryID,
						   let dictionaryNoteCategories: [DictionaryNoteCategory] = try? context.fetch(DictionaryNoteCategory.fetchRequest()) {
							note.category = dictionaryNoteCategories.first(where: { $0.id == categoryID })
						}
						
						return note
					}
					.sorted { $0.date < $1.date }
			}
			
			// Exams
			if let storedExams = try? context.fetch(StoredExam.fetchRequest()) as? [StoredExam] {
				self.tasks.exams = storedExams
					.compactMap { storedExam in
						guard let exam = Exam(from: storedExam) else {
							return nil
						}
												
						exam.subject = dictionarySubjects.first(where: { $0.id == exam.subjectID })
						exam.employee = dictionaryEmployees.first(where: { $0.id == exam.employeeID })
						
						return exam
					}
					.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
			}
			
			// Homework
			if let storedHomework = try? context.fetch(StoredHomework.fetchRequest()) as? [StoredHomework] {
				self.tasks.homework = storedHomework
					.compactMap { storedHomework in
						guard let homework = Homework(from: storedHomework) else {
							return nil
						}
												
						homework.subject = dictionarySubjects.first(where: { $0.id == homework.subjectID })
						homework.employee = dictionaryEmployees.first(where: { $0.id == homework.employeeID })
						
						return homework
					}
					.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
			}
			
			// Messages
			if let storedMessages = try? context.fetch(StoredMessage.fetchRequest()) as? [StoredMessage] {
				let sentMessages: [Vulcan.Message] = storedMessages
					.filter { $0.folder == "Wyslane" && $0.status == "Widoczna" }
					.compactMap { entity in
						let message = Vulcan.Message(from: entity)
						message?.tag = .sent
						
						return message
					}
					.sorted { $0.dateSent > $1.dateSent }
				
				let receivedMessages: [Vulcan.Message] = storedMessages
					.filter { $0.folder == "Odebrane" && $0.status == "Widoczna" }
					.compactMap { entity in
						let message = Vulcan.Message(from: entity)
						message?.tag = .received
						
						return message
					}
					.sorted { $0.dateSent > $1.dateSent }
				
				let deletedMessages: [Vulcan.Message] = storedMessages
					.filter { $0.status == "Usunieta" }
					.compactMap { entity in
						let message = Vulcan.Message(from: entity)
						message?.tag = .deleted
						
						return message
					}
					.sorted { $0.dateSent > $1.dateSent }
				
				self.messages[.sent] = sentMessages
				self.messages[.received] = receivedMessages
				self.messages[.deleted] = deletedMessages
			}
			
			logger.info("Done!")
		} else {
			logger.error("Couldn't fetch dictionary!")
		}
		
		// Logged-in specific code
		if self.ud.bool(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue) {
			// Refresh users
			self.getUsers()
		}
	}
	
	// MARK: - Base functions
	
	/// Register new device and save received certificate.
	/// - Parameters:
	///   - token: 7 alphanumeric all-caps characters, which first three of them are the endpoint ID
	///   - symbol: Alphanumeric, lower-caps school symbol
	///   - pin: 6 numbers
	///   - completionHandler: Callback
	public func login(token: String, symbol: String, pin: Int, completionHandler: @escaping (Bool, Error?) -> ()) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Login")
		logger.debug("Logging in...")

		// Apple Review
		if (token == "applepark" && symbol == "infiniteloop" && pin == 000941) {
			let user: Vulcan.Student = Vulcan.Student(classificationPeriodID: 1, periodLevel: 1, periodNumber: 1, periodDateFrom: 1, periodDateTo: 1, reportingUnitID: 1, reportingUnitShort: "AAPL", reportingUnitName: "Apple", reportingUnitSymbol: "AAPL", unitID: 1, unitName: "Apple", unitShort: "AAPL", unitSymbol: "AAPL", unitCode: "AAPL", userRole: "", userLogin: "johnappleseed@apple.com", userLoginID: 1, username: "JohnAppleseed", id: 1, branchID: 1, name: "John", secondName: "", surname: "Appleseed", nickname: nil, userGender: 1, position: 1, loginID: nil)
			self.setUser(user)
			completionHandler(true, nil)
			return
		}
		
		// Endpoint request
		let endpointPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: "http://komponenty.vulcan.net.pl/UonetPlusMobile/RoutingRules.txt")!)
			.mapError { $0 as Error }
			.eraseToAnyPublisher()
		
		// Firebase request
		var firebaseRequest: URLRequest = URLRequest(url: URL(string: "https://android.googleapis.com/checkin")!)
		firebaseRequest.httpMethod = "POST"
		firebaseRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
		firebaseRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		let firebaseRequestBody: [String: Any] = [
			"locale": "pl_PL",
			"digest": "",
			"checkin": [
				"iosbuild": [
					"model": Bundle.main.modelName,
					"os_version": Bundle.main.systemVersion
				],
				"last_checkin_msec": 0,
				"user_number": 0,
				"type": 2
			],
			"time_zone": "Europe/Warsaw",
			"user_serial_number": 0,
			"id": 0,
			"logging_id": 0,
			"version": 2,
			"security_token": 0,
			"fragment": 0
		]
		firebaseRequest.httpBody = try? JSONSerialization.data(withJSONObject: firebaseRequestBody)
		
		let firebasePublisher = URLSession.shared.dataTaskPublisher(for: firebaseRequest)
			.receive(on: DispatchQueue.global(qos: .background))
			.mapError { $0 as Error }
			.tryCompactMap { value -> AnyPublisher<Data, Error> in
				guard let dictionary: [String: Any] = try? JSONSerialization.jsonObject(with: value.data, options: []) as? [String: Any] else {
					throw APIError.error(reason: "Error serializing JSON")
				}
				
				var request: URLRequest = URLRequest(url: URL(string: "https://fcmtoken.googleapis.com/register")!)
				request.httpMethod = "POST"
				request.setValue("AidLogin \(dictionary["android_id"] as? Int ?? 0):\(dictionary["security_token"] as? Int ?? 0)", forHTTPHeaderField: "Authorization")
				request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
				
				let body: String = "device=\(dictionary["android_id"] as? Int ?? 0)&app=pl.vulcan.UonetMobileModulUcznia&sender=987828170337&X-subtype=987828170337&appid=dLIDwhjvE58&gmp_app_id=1:987828170337:ios:6b65a4ad435fba7f"
				request.httpBody = body.data(using: .utf8)
				
				return URLSession.shared.dataTaskPublisher(for: request)
					.receive(on: DispatchQueue.global(qos: .background))
					.mapError { $0 as Error }
					.map { $0.data }
					.eraseToAnyPublisher()
			}
			.flatMap { $0 }
			.mapError { $0 }
			.eraseToAnyPublisher()
		
		Publishers.Zip(endpointPublisher, firebasePublisher)
			.receive(on: DispatchQueue.main)
			.tryMap { (endpoints, firebaseToken) -> String in
				// Find endpointURL
				let lines = String(data: endpoints.data, encoding: .utf8)?.split { $0.isNewline }
				var endpointURL: String?
				
				// Parse lines
				lines?.forEach { (line) in
					let items = line.split(separator: ",")
					if (token.starts(with: items[0])) {
						// We found our URL
						endpointURL = String(items[1])
						return
					}
				}
				
				guard let finalEndpointURL: String = endpointURL else {
					throw APIError.error(reason: "No endpoint URL found")
				}
				
				// Get Firebase token
				let token: String? = String(data: firebaseToken, encoding: .utf8)?.components(separatedBy: "token=").last
				if (token == nil) {
					logger.error("Token empty! Response: \"\(firebaseToken.base64EncodedString(), privacy: .private)\"")
				}
				logger.debug("Token: \(firebaseToken.count)B")
				self.keychain["FirebaseToken"] = token
				
				// return finalEndpointURL
				return finalEndpointURL
			}
			.tryCompactMap { url -> AnyPublisher<Data, Error> in
				// Start configuring request
				var request: URLRequest = URLRequest(url: URL(string: "\(url)/\(symbol)/mobile-api/Uczen.v3.UczenStart/Certyfikat")!)
				request.httpMethod = "POST"
				
				guard let firebaseToken: String = self.keychain["FirebaseToken"] else {
					throw APIError.error(reason: "No FirebaseToken")
				}
				
				// Headers
				request.setValue("RegisterDevice", forHTTPHeaderField: "RequestMobileType")
				request.setValue("MobileUserAgent", forHTTPHeaderField: "User-Agent")
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
				
				// Body
				let timeNow: UInt64 = UInt64(floor(NSDate().timeIntervalSince1970))
				
				let body: [String: Any] = [
					"RequestId": UUID().uuidString,
					"TimeKey": (timeNow - 1),
					"RemoteMobileTimeKey": timeNow,
					"RemoteMobileAppVersion": "20.4.1.358",
					"RemoteMobileAppName": "VULCAN-iOS-ModulUcznia",
					"AppVersion": Bundle.main.buildVersion,
					"DeviceId": UUID().uuidString,
					"DeviceName": "vulcan @ \(Bundle.main.deviceName)",
					"DeviceNameUser": Bundle.main.deviceName,
					"DeviceDescription": "",
					"DeviceSystemType": Bundle.main.systemName,
					"DeviceSystemVersion": Bundle.main.systemVersion,
					"TokenKey": token,
					"PIN": String(pin),
					"FirebaseTokenKey": firebaseToken
				]
				let bodyData = try? JSONSerialization.data(withJSONObject: body)
				request.httpBody = bodyData
				
				// Send the request and pass it
				return URLSession.shared.dataTaskPublisher(for: request)
					.receive(on: DispatchQueue.main)
					.mapError { $0 as Error }
					.map { $0.data }
					.eraseToAnyPublisher()
			}
			.flatMap { $0 }
			.tryMap { data -> [String: Any]? in
				// Parse certificate
				guard let json: [String: Any] = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
					throw APIError.error(reason: "Error serializing JSON")
				}
				
				// Check for errors
				if (json["IsError"] as? Bool ?? true) {
					logger.error("IsError!")
					logger.debug("\(json)")
					throw APIError.error(reason: json["Message"] as? String ?? "Unknown")
				}
				
				return json["TokenCert"] as? [String: Any]
			}
			.sink(receiveCompletion: { (completion) in
				logger.info("Completion: \(String(describing: completion))")
				switch (completion) {
					case .finished:
						self.ud.setValue(true, forKey: UserDefaults.AppKeys.isLoggedIn.rawValue)
						logger.debug("Finished logging in!")
						completionHandler(true, nil)
						self.getUsers()
					case .failure(let error):
						logger.error("Error logging in: \(error.localizedDescription)")
						completionHandler(false, error)
						self.logOut()
				}
			}, receiveValue: { certificate in
				guard let certificate: [String: Any] = certificate else {
					logger.debug("`certificate` isn't a dictionary! Returning.")
					return
				}
				
				// Purge all saved data
				self.logOut()
				
				// Save certificate
				self.keychain["CertificatePfx"] = certificate["CertyfikatPfx"] as? String
				self.keychain["CertificateKey"] = certificate["CertyfikatKlucz"] as? String
				self.keychain["CertificateCreated"] = certificate["CertyfikatDataUtworzenia"] as? String
				self.keychain["Username"] = certificate["UzytkownikNazwa"] as? String
				self.endpointURL = certificate["AdresBazowyRestApi"] as? String
				
				logger.debug("Parsed certificate! Key: \(self.keychain["CertificateKey"] ?? "", privacy: .sensitive).")
			})
			.store(in: &cancellableSet)
	}
	
	/// Logs out, removing all stored data.
	public func logOut() {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Logout")
		logger.debug("Logging out!")
		
		// Keychain
		do {
			logger.debug("Removing Keychain...")
			try self.keychain.removeAll()
			logger.debug("Done!")
		} catch {
			logger.error("Error removing Keychain: \(error.localizedDescription)")
		}
		
		// Variables
		ud.removeObject(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue)
		ud.removeObject(forKey: UserDefaults.AppKeys.userID.rawValue)
		ud.removeObject(forKey: UserDefaults.AppKeys.showAllScheduleEvents.rawValue)
		ud.removeObject(forKey: UserDefaults.AppKeys.readMessageOnOpen.rawValue)
		ud.removeObject(forKey: UserDefaults.AppKeys.dictionaryLastFetched.rawValue)
		
		// CoreData
		CoreDataModel.shared.clearDatabase()
		
		logger.debug("Finished logging out.")
	}
	
	/// Sets the default user
	/// - Parameter user: Selected user
	/// - Parameter force: Force dictionary update
	public func setUser(_ user: Vulcan.Student, force: Bool = false) {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Users")
		logger.debug("Setting default user with ID \(user.id, privacy: .sensitive) (\(user.loginID ?? -1, privacy: .sensitive) : \(user.userLoginID, privacy: .sensitive)).")
		
		ud.setValue(true, forKey: UserDefaults.AppKeys.isLoggedIn.rawValue)
		ud.setValue(user.id, forKey: UserDefaults.AppKeys.userID.rawValue)
		self.currentUser = user
		self.getDictionary(force: force)
	}
	
	/// Fetches and saves the dictionary.
	/// - Parameter force: Ignore the saved dictionary?
	public func getDictionary(force: Bool = false) {
		if (self.dataState.dictionary.loading) {
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Dictionary")
		
		// Return if no user/no endpoint URL
		guard let user: Vulcan.Student = self.currentUser, let endpointURL: String = self.endpointURL else {
			logger.error("Not logged in")
			return
		}
		
		let lastFetched: Date = Date(timeIntervalSince1970: TimeInterval(ud.integer(forKey: UserDefaults.AppKeys.dictionaryLastFetched.rawValue)))
		let shouldUpdate: Bool = (lastFetched < (Calendar.autoupdatingCurrent.date(byAdding: .month, value: -1, to: Date()) ?? Date().startOfMonth)) || force
				
		// Should we update?
		if (!shouldUpdate) {
			logger.debug("Dictionary available - not updating. Date: \(lastFetched) (Age: \(Date(timeInterval: -(Date() - lastFetched), since: Date()).timestampString ?? "Unknown")).")
			return
		}
		
		logger.debug("Updating dictionary...")
		
		let request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/Slowniki")!)
		self.dataState.dictionary.loading = true
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data -> [String: Any]? in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let data = json["Data"] as? [String: Any] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return data
				}
				.sink(receiveCompletion: { completion in
					logger.debug("Finished: \(String(describing: completion))")
					self.dataState.dictionary.loading = false
					switch (completion) {
						case .finished:
							break
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
					}
				}, receiveValue: { dictionary in
					guard let dictionary: [String: Any] = dictionary else {
						logger.error("Error serializing data")
						return
					}
					
					let context = self.persistentContainer.viewContext
					
					// Teachers + Employees
					if let teachersDictionary: [[String: Any]] = dictionary["Nauczyciele"] as? [[String: Any]],
					   let employeesDictionary: [[String: Any]] = dictionary["Pracownicy"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: (teachersDictionary + employeesDictionary), options: []) {
						let decoded: [Vulcan.Employee]? = try? JSONDecoder().decode([Vulcan.Employee].self, from: data)
						if let decoded = decoded?.uniques {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryEmployee.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryEmployee(context: context)
								object.code = item.code
								object.id = Int64(item.id)
								object.name = item.name
								object.surname = item.surname
								
								if let loginID = item.loginID { object.loginID = Int32(loginID) }
								if let active = item.active { object.active = active }
								if let teacher = item.teacher { object.teacher = teacher }
							}
						}
					}
					
					// Subjects
					if let rawDictionary: [[String: Any]] = dictionary["Przedmioty"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.Subject]? = try? JSONDecoder().decode([Vulcan.Subject].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionarySubject.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionarySubject(context: context)
								object.active = item.active
								object.code = item.code
								object.id = Int64(item.id)
								object.name = item.name
								object.position = Int16(item.position)
							}
						}
					}
					
					// Lesson times
					if let rawDictionary: [[String: Any]] = dictionary["PoryLekcji"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.LessonTime]? = try? JSONDecoder().decode([Vulcan.LessonTime].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryLessonTime.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryLessonTime(context: context)
								object.end = Int32(item.end)
								object.id = Int64(item.id)
								object.number = Int16(item.number)
								object.start = Int32(item.start)
							}
						}
					}
					
					// Grade categories
					if let rawDictionary: [[String: Any]] = dictionary["KategorieOcen"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.GradeCategory]? = try? JSONDecoder().decode([Vulcan.GradeCategory].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryGradeCategory.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryGradeCategory(context: context)
								object.code = item.code
								object.id = Int64(item.id)
								object.name = item.name
							}
						}
					}
					
					// Note categories
					if let rawDictionary: [[String: Any]] = dictionary["KategorieUwag"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.NoteCategory]? = try? JSONDecoder().decode([Vulcan.NoteCategory].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryNoteCategory.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryNoteCategory(context: context)
								object.active = item.active
								object.id = Int64(item.id)
								object.name = item.name
							}
						}
					}
					
					// Presence categories
					if let rawDictionary: [[String: Any]] = dictionary["KategorieFrekwencji"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.PresenceCategory]? = try? JSONDecoder().decode([Vulcan.PresenceCategory].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryPresenceCategory.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryPresenceCategory(context: context)
								object.justified = item.justified
								object.exempt = item.exempt
								object.id = Int64(item.id)
								object.late = item.late
								object.name = item.name
								object.position = Int16(item.position)
								object.present = item.present
								object.removed = item.removed
							}
						}
					}
					
					// Presence types
					if let rawDictionary: [[String: Any]] = dictionary["TypyFrekwencji"] as? [[String: Any]],
					   let data: Data = try? JSONSerialization.data(withJSONObject: rawDictionary, options: []) {
						let decoded: [Vulcan.PresenceType]? = try? JSONDecoder().decode([Vulcan.PresenceType].self, from: data)
						if let decoded = decoded {
							let deleteRequest = NSBatchDeleteRequest(fetchRequest: DictionaryPresenceType.fetchRequest())
							
							do {
								try context.execute(deleteRequest)
							} catch {
								logger.error("Error executing request: \(error.localizedDescription)")
							}
							
							for item in decoded {
								let object = DictionaryPresenceType(context: context)
								object.active = item.active
								object.categoryID = Int32(item.categoryID)
								object.id = Int64(item.id)
								object.isDefault = item.isDefault
								object.name = item.name
								object.symbol = item.symbol
							}
						}
					}
					
					// Save
					CoreDataModel.shared.saveContext(force: true)
					self.ud.setValue(Int(Date().timeIntervalSince1970), forKey: UserDefaults.AppKeys.dictionaryLastFetched.rawValue)
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.dictionary.loading = false
		}
	}
	
	// MARK: - Data functions
	
	/// Get and parse available users.
	/// - Parameter completionHandler: Callback
	public func getUsers(completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if already pending
		if (self.dataState.users.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Users")
		logger.debug("Requesting users...")
		
		let request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)mobile-api/Uczen.v3.UczenStart/ListaUczniow")!)
		self.dataState.users.loading = true
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects = json["Data"] as? [[String: Any]] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return try JSONSerialization.data(withJSONObject: objects, options: [])
				}
				.decode(type: [Vulcan.Student].self, decoder: JSONDecoder())
				.sink(receiveCompletion: { (completion) in
					self.dataState.users.loading = false
					switch completion {
						case .finished:
							self.dataState.users.lastFetched = Date()
							completionHandler(nil)
							if let user: Vulcan.Student = self.users.first(where: { $0.id == self.ud.integer(forKey: UserDefaults.AppKeys.userID.rawValue) }) {
								self.setUser(user)
							} else if (self.users.count == 1), let user: Vulcan.Student = self.users.first {
								self.setUser(user)
							}
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { users in
					logger.debug("Received \(users.count) user(s).")
					self.users = users
					
					let context = self.persistentContainer.viewContext
					let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredStudent.fetchRequest())
					
					do {
						try context.execute(deleteRequest)
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
					
					for user in users {
						_ = user.entity(context: context)
					}
					
					CoreDataModel.shared.saveContext()
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.users.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's schedule.
	/// - Parameter isPersistent: Should data be preserved?
	/// - Parameter startDate: From this date
	/// - Parameter endDate: To this date
	/// - Parameter completionHandler: Callback
	public func getSchedule(isPersistent: Bool = true, from startDate: Date, to endDate: Date, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.schedule.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
				
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Schedule")
		logger.debug("Getting schedule of user with ID \(user.userLoginID, privacy: .private) from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd")) (persistent: \(isPersistent))...")
		self.dataState.schedule.loading = true
		
		var tempSchedule = self.schedule
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/PlanLekcjiZeZmianami")!)
		
		let body: [String: Any] = [
			"DataPoczatkowa": startDate.formattedString(format: "yyyy-MM-dd"),
			"DataKoncowa": endDate.formattedString(format: "yyyy-MM-dd"),
			"IdOddzial": user.unitID,
			"IdOkresKlasyfikacyjny": user.classificationPeriodID,
			"IdUczen": user.id,
			"LoginId": user.userLoginID
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects = json["Data"] as? [[String: Any]] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return try JSONSerialization.data(withJSONObject: objects, options: [])
				}
				.decode(type: [Vulcan.ScheduleEvent].self, decoder: JSONDecoder())
				.sink(receiveCompletion: { (completion) in
					self.dataState.schedule.loading = false
					switch completion {
						case .finished:
							self.schedule = tempSchedule
							self.dataState.schedule.lastFetched = Date()
							self.scheduleDidChange.send(isPersistent)
							completionHandler(nil)

							if self.ud.bool(forKey: UserDefaults.AppKeys.enableScheduleNotifications.rawValue) {
								self.schedule
									.flatMap(\.events)
									.filter { $0.dateStarts != nil && $0.dateStarts ?? $0.date >= Date() }
									.filter { $0.isUserSchedule }
									.forEach(self.addScheduleEventNotification)
							}
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { events in
					logger.debug("Received \(events.count) event(s).")
					
					let context = self.persistentContainer.viewContext
					guard let dictionarySubjects: [DictionarySubject] = try? context.fetch(DictionarySubject.fetchRequest()),
						  let dictionaryEmployees: [DictionaryEmployee] = try? context.fetch(DictionaryEmployee.fetchRequest()),
						  let dictionaryLessonTimes: [DictionaryLessonTime] = try? context.fetch(DictionaryLessonTime.fetchRequest()) else {
						logger.error("Couldn't fetch entities!")
						return
					}
					
					tempSchedule = Dictionary(grouping: events.sorted { $0.lessonOfTheDay < $1.lessonOfTheDay }, by: \.date)
						.compactMap { date, events in
							let events = events
								.map { event -> Vulcan.ScheduleEvent in
									var event = event
									
									if let subject: DictionarySubject = dictionarySubjects.first(where: { $0.id == event.subjectID }) {
										event.subject = subject
									}
									
									if let employee: DictionaryEmployee = dictionaryEmployees.first(where: { $0.id == event.employeeID }),
									   let employeeName = employee.name,
									   let employeeSurname = employee.surname {
										event.employee = employee
										event.employeeFullName = "\(employeeName) \(employeeSurname)"
									}
									
									if let lessonTime: DictionaryLessonTime = dictionaryLessonTimes.first(where: { $0.id == event.lessonTimeID }) {
										event.dateStartsEpoch = TimeInterval(event.dateEpoch + Int(lessonTime.start) + 3600)
										event.dateEndsEpoch = TimeInterval(event.dateEpoch + Int(lessonTime.end) + 3600)
									}
																		
									return event
								}
								.sorted { $0.lessonOfTheDay < $1.lessonOfTheDay }
							
							return Vulcan.Schedule(date: date, events: events)
						}
						.sorted { $0.date < $1.date }
					
					if isPersistent {
						let context = self.persistentContainer.viewContext
						let events = tempSchedule.flatMap(\.events)
						
						do {
							let oneMonthAgo: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: -1, to: Date()) ?? Date().startOfMonth
							let oneMonthInFuture: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 1, to: Date()) ?? Date().endOfMonth
							
							let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoredScheduleEvent.fetchRequest()
							if let startPeriod = events.first?.date.startOfDay,
							   let endPeriod = events.last?.date.endOfDay {
								fetchRequest.predicate = NSPredicate(
									format: "(dateEpoch >= %i AND dateEpoch <= %i) OR (dateEpoch <= %i OR dateEpoch >= %i)",
									Int(startPeriod.timeIntervalSince1970),
									Int(endPeriod.timeIntervalSince1970),
									Int(oneMonthAgo.timeIntervalSince1970),
									Int(oneMonthInFuture.timeIntervalSince1970)
								)
							} else {
								fetchRequest.predicate = NSPredicate(format: "dateEpoch <= %i OR dateEpoch >= %i", Int(oneMonthAgo.timeIntervalSince1970), Int(oneMonthInFuture.timeIntervalSince1970))
							}
														
							try context.execute(NSBatchDeleteRequest(fetchRequest: fetchRequest))
						} catch {
							logger.error("Error executing request: \(error.localizedDescription)")
						}
						
						for event in tempSchedule.flatMap(\.events) {
							_ = event.entity(context: context)
						}
						
						CoreDataModel.shared.saveContext()
					}
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.schedule.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's grades.
	/// - Parameter isPersistent: Should data be preserved?
	/// - Parameter completionHandler: Callback
	public func getGrades(isPersistent: Bool = true, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.grades.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Grades")
		logger.debug("Getting grades of user with ID \(user.userLoginID, privacy: .private)...")
		self.dataState.grades.loading = true
		
		var tempGrades = self.grades
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/Oceny")!)
		
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.classificationPeriodID,
			"IdUczen": user.id
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects = json["Data"] as? [[String: Any]] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return try JSONSerialization.data(withJSONObject: objects, options: [])
				}
				.decode(type: [Vulcan.Grade].self, decoder: JSONDecoder())
				.sink(receiveCompletion: { (completion) in
					self.dataState.grades.loading = false
					switch completion {
						case .finished:
							self.grades = tempGrades
							self.dataState.grades.lastFetched = Date()
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { grades in
					logger.debug("Received \(grades.count) grade(s).")
					
					let context = self.persistentContainer.viewContext
					guard let dictionarySubjects: [DictionarySubject] = try? context.fetch(DictionarySubject.fetchRequest()),
						  let dictionaryEmployees: [DictionaryEmployee] = try? context.fetch(DictionaryEmployee.fetchRequest()),
						  let dictionaryGradeCategories: [DictionaryGradeCategory] = try? context.fetch(DictionaryGradeCategory.fetchRequest()) else {
						logger.error("Couldn't fetch entities!")
						return
					}
					
					let dictionary = Dictionary(grouping: grades, by: \.subjectID)
					tempGrades = dictionary
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
							
							let grades: [Vulcan.Grade] = grades
								.map { grade -> Vulcan.Grade in
									var grade = grade
									
									if let categoryID = grade.categoryID {
										grade.category = dictionaryGradeCategories.first(where: { $0.id == categoryID })
									}
									
									return grade
								}
								.sorted { ($0.dateCreated, $0.entry ?? "") < ($1.dateCreated, $1.entry ?? "") }
							
							let subjectGrades = Vulcan.SubjectGrades(subject: subject, employee: employee, grades: grades)
							
							if let currentSubjectGrades = self.grades.first(where: { $0.subject.id == subject.id })?.grades {
								subjectGrades.hasNewItems = grades.sorted(by: { ($0.dateCreated, $0.entry ?? "") < ($1.dateCreated, $1.entry ?? "") }) != currentSubjectGrades.sorted(by: { ($0.dateCreated, $0.entry ?? "") < ($1.dateCreated, $1.entry ?? "") })
							} else {
								subjectGrades.hasNewItems = true
							}
							
							return subjectGrades
						}
						.sorted { $0.subject.name < $1.subject.name }
					
					if isPersistent {
						let context = self.persistentContainer.viewContext
						let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredGrade.fetchRequest())
						
						do {
							try context.execute(deleteRequest)
						} catch {
							logger.error("Error executing request: \(error.localizedDescription)")
						}
						
						for grade in grades {
							_ = grade.entity(context: context)
						}
						
						CoreDataModel.shared.saveContext()
					}
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.grades.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's final grades.
	/// - Parameter completionHandler: Callback
	public func getEndOfTermGrades(completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.eotGrades.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "EOTGrades")
		logger.debug("Getting end of term grades of user with ID \(user.userLoginID, privacy: .private)...")
		self.dataState.eotGrades.loading = true
		
		var tempEOTGrades = self.eotGrades
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/OcenyPodsumowanie")!)
		
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.classificationPeriodID,
			"IdUczen": user.id,
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data -> ([Vulcan.EndOfTermGrade], [Vulcan.EndOfTermGrade], [Vulcan.EndOfTermPoints]) in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects: [String: Any] = json["Data"] as? [String: Any] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					guard let expectedObjects: [[String: Any]] = objects["OcenyPrzewidywane"] as? [[String: Any]],
						  let expectedData: Data = try? JSONSerialization.data(withJSONObject: expectedObjects, options: []),
						  let finalObjects: [[String: Any]] = objects["OcenyKlasyfikacyjne"] as? [[String: Any]],
						  let finalData: Data = try? JSONSerialization.data(withJSONObject: finalObjects, options: []),
						  let pointsObjects: [[String: Any]] = objects["SrednieOcen"] as? [[String: Any]],
						  let pointsData: Data = try? JSONSerialization.data(withJSONObject: pointsObjects, options: [])
					else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					let decoder: JSONDecoder = JSONDecoder()
					return (
						try decoder.decode([Vulcan.EndOfTermGrade].self, from: expectedData),
						try decoder.decode([Vulcan.EndOfTermGrade].self, from: finalData),
						try decoder.decode([Vulcan.EndOfTermPoints].self, from: pointsData))
				}
				.sink(receiveCompletion: { (completion) in
					self.dataState.eotGrades.loading = false
					switch completion {
						case .finished:
							self.eotGrades = tempEOTGrades
							self.dataState.eotGrades.lastFetched = Date()
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { expected, final, points in
					logger.debug("Received \(expected.count) expected, \(final.count) final grade(s) and \(points.count) points object(s).")
					
					let context = self.persistentContainer.viewContext
					guard let dictionarySubjects: [DictionarySubject] = try? context.fetch(DictionarySubject.fetchRequest()) else {
						logger.error("Couldn't fetch entities!")
						return
					}
					
					let expectedGrades: [EndOfTermGrade] = expected
						.map { grade in
							var grade = grade
							grade.subject = dictionarySubjects.first(where: { $0.id == grade.subjectID })
							grade.type = .expected
							
							return grade
						}
						.sorted { $0.subject?.name ?? "" < $1.subject?.name ?? "" }
					
					let finalGrades: [EndOfTermGrade] = final
						.map { grade in
							var grade = grade
							grade.subject = dictionarySubjects.first(where: { $0.id == grade.subjectID })
							grade.type = .final
							
							return grade
						}
						.sorted { $0.subject?.name ?? "" < $1.subject?.name ?? "" }
					
					tempEOTGrades = (expectedGrades + finalGrades).sorted { ($0.type ?? .unknown) < ($1.type ?? .unknown) }
					
					do {
						try context.execute(NSBatchDeleteRequest(fetchRequest: StoredEndOfTermGrade.fetchRequest()))
						try context.execute(NSBatchDeleteRequest(fetchRequest: StoredEndOfTermPoints.fetchRequest()))
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
					
					for grade in self.eotGrades {
						_ = grade.entity(context: context)
					}
					
					for subjectPoints in points {
						_ = subjectPoints.entity(context: context)
					}
					
					CoreDataModel.shared.saveContext()
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.eotGrades.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's notes.
	/// - Parameter completionHandler: Callback
	public func getNotes(completionHandler: @escaping (Error?) -> () = { _  in }) {		
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.notes.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Notes")
		logger.debug("Getting notes of user with ID \(user.userLoginID, privacy: .private)...")
		self.dataState.notes.loading = true
		
		var tempNotes = self.notes
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/UwagiUcznia")!)
		
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.classificationPeriodID,
			"IdUczen": user.id,
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects = json["Data"] as? [[String: Any]] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return try JSONSerialization.data(withJSONObject: objects, options: [])
				}
				.decode(type: [Vulcan.Note].self, decoder: JSONDecoder())
				.sink(receiveCompletion: { (completion) in
					self.dataState.notes.loading = false
					switch completion {
						case .finished:
							self.notes = tempNotes
							self.dataState.notes.lastFetched = Date()
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { notes in
					logger.debug("Received \(notes.count) note(s).")
					
					let context = self.persistentContainer.viewContext
					guard let dictionaryEmployees: [DictionaryEmployee] = try? context.fetch(DictionaryEmployee.fetchRequest()),
						  let dictionaryNoteCategories: [DictionaryNoteCategory] = try? context.fetch(DictionaryNoteCategory.fetchRequest()) else {
						logger.error("Couldn't fetch entities!")
						return
					}
					
					tempNotes = notes
						.map { note in
							var note = note
							note.employee = dictionaryEmployees.first(where: { $0.id == note.employeeID })
							if let categoryID = note.categoryID,
							   let category = dictionaryNoteCategories.first(where: { $0.id == categoryID }) {
								note.category = category
							}
							
							return note
						}
						.sorted { $0.date < $1.date }
					
					let deleteRequest = NSBatchDeleteRequest(fetchRequest: StoredNote.fetchRequest())
					
					do {
						try context.execute(deleteRequest)
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
					
					for note in notes {
						_ = note.entity(context: context)
					}
					
					CoreDataModel.shared.saveContext()
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.notes.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's tasks.
	/// - Parameters:
	///   - isPersistent: Should data be preserved?
	///   - startDate: From this date
	///   - endDate: To this date
	///   - completionHandler: Callback
	public func getTasks(isPersistent: Bool = true, from startDate: Date, to endDate: Date, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.tasks.loading) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Tasks")
		logger.debug("Getting tasks from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd")) (persistent: \(isPersistent))...")
		self.dataState.tasks.loading = true
		
		var tempTasks = self.tasks
		
		let body: [String: Any] = [
			"DataPoczatkowa": startDate.formattedString(format: "yyyy-MM-dd"),
			"DataKoncowa": endDate.formattedString(format: "yyyy-MM-dd"),
			"IdOddzial": user.branchID,
			"IdOkresKlasyfikacyjny": user.classificationPeriodID,
			"IdUczen": user.id,
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		
		var examsRequest: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/Sprawdziany")!)
		examsRequest.httpBody = bodyData
		
		var homeworkRequest: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/ZadaniaDomowe")!)
		homeworkRequest.httpBody = bodyData
		
		do {
			let examsPublisher = try self.request(examsRequest)
			let homeworkPublisher = try self.request(homeworkRequest)
			
			Publishers.Zip(examsPublisher, homeworkPublisher)
				.receive(on: DispatchQueue.main)
				.tryMap { examsResponse, homeworkResponse -> ([Vulcan.Exam], [Vulcan.Homework]) in
					let decoder: JSONDecoder = JSONDecoder()
					let error = APIError.error(reason: "Error serializing JSON")
					
					// Exams
					guard let examsJSON = try JSONSerialization.jsonObject(with: examsResponse, options: []) as? [String: Any],
						  let examsObject = examsJSON["Data"] as? [[String: Any]],
						  let examsData = try? JSONSerialization.data(withJSONObject: examsObject, options: []),
						  let exams = try? decoder.decode([Vulcan.Exam].self, from: examsData) else {
						throw error
					}
					
					// Homework
					guard let homeworkJSON = try JSONSerialization.jsonObject(with: homeworkResponse, options: []) as? [String: Any],
						  let homeworkObject = homeworkJSON["Data"] as? [[String: Any]],
						  let homeworkData = try? JSONSerialization.data(withJSONObject: homeworkObject, options: []),
						  let homework = try? decoder.decode([Vulcan.Homework].self, from: homeworkData) else {
						throw error
					}
					
					return (exams, homework)
				}
				.sink(receiveCompletion: { completion in
					self.dataState.tasks.loading = false
					switch completion {
						case .finished:
							self.tasks = tempTasks
							self.dataState.tasks.lastFetched = Date()
							completionHandler(nil)
							
							if self.ud.bool(forKey: UserDefaults.AppKeys.enableTaskNotifications.rawValue) {
								tempTasks.exams
									.filter { $0.date >= Date() }
									.forEach { task in
										self.addTaskNotification(task, isBigType: task.isBigType)
									}
								
								tempTasks.homework
									.filter { $0.date >= Date() }
									.forEach { task in
										self.addTaskNotification(task)
									}
							}
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { exams, homework in
					logger.debug("Received \(exams.count) exam and \(homework.count) homework task(s).")
					
					let context = self.persistentContainer.viewContext
					guard let dictionarySubjects: [DictionarySubject] = try? context.fetch(DictionarySubject.fetchRequest()),
						  let dictionaryEmployees: [DictionaryEmployee] = try? context.fetch(DictionaryEmployee.fetchRequest()) else {
						logger.error("Couldn't fetch entities!")
						return
					}
					
					let exams: [Vulcan.Exam] = exams
						.map { exam in
							exam.subject = dictionarySubjects.first(where: { $0.id == exam.subjectID })
							exam.employee = dictionaryEmployees.first(where: { $0.id == exam.employeeID })
							
							return exam
						}
						.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
					
					let homework: [Vulcan.Homework] = homework
						.map { task in
							task.subject = dictionarySubjects.first(where: { $0.id == task.subjectID })
							task.employee = dictionaryEmployees.first(where: { $0.id == task.employeeID })
							
							return task
						}
						.sorted { ($0.date, $0.subject?.name ?? "", $0.entry) < ($1.date, $1.subject?.name ?? "", $1.entry) }
					
					tempTasks = Vulcan.Tasks(exams: exams, homework: homework)
					
					if isPersistent {
						do {
							// let oneMonthAgo: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: -1, to: Date()) ?? Date().startOfMonth
							// let oneMonthInFuture: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 1, to: Date()) ?? Date().endOfMonth
							
							let examsFetchRequest: NSFetchRequest<NSFetchRequestResult> = StoredExam.fetchRequest()
							// examsFetchRequest.predicate = NSPredicate(format: "dateEpoch <= %i OR dateEpoch >= %i", Int(oneMonthAgo.timeIntervalSince1970), Int(oneMonthInFuture.timeIntervalSince1970))
							
							let homeworkFetchRequest: NSFetchRequest<NSFetchRequestResult> = StoredHomework.fetchRequest()
							// homeworkFetchRequest.predicate = NSPredicate(format: "dateEpoch <= %i OR dateEpoch >= %i", Int(oneMonthAgo.timeIntervalSince1970), Int(oneMonthInFuture.timeIntervalSince1970))
							
							try context.execute(NSBatchDeleteRequest(fetchRequest: examsFetchRequest))
							try context.execute(NSBatchDeleteRequest(fetchRequest: homeworkFetchRequest))
						} catch {
							logger.error("Error executing request: \(error.localizedDescription)")
						}
						
						for exam in exams {
							_ = exam.entity(context: context)
						}
						
						for task in homework {
							_ = task.entity(context: context)
						}
						
						CoreDataModel.shared.saveContext()
					}
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.tasks.loading = false
			completionHandler(error)
		}
	}
	
	/// Gets selected user's messages with a specified tag.
	/// - Parameters:
	///   - tag: Messages tag
	///   - isPersistent: Should data be preserved?
	///   - startDate: From this date
	///   - endDate: To this date
	///   - completionHandler: Callback
	public func getMessages(tag: Vulcan.MessageTag, isPersistent: Bool = true, from startDate: Date, to endDate: Date, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.messages[tag]?.loading ?? true) {
			completionHandler(nil)
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Messages")
		logger.debug("Getting messages of user with ID \(user.userLoginID, privacy: .private) with tag \"\(tag.rawValue)\" from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd")) (persistent: \(isPersistent))...")
		self.dataState.messages[tag]?.loading = true
		
		var tempMessages = self.messages[tag] ?? []
		
		var tagEndpoint: String
		switch (tag) {
			case .received:	tagEndpoint = "WiadomosciOdebrane"
			case .deleted:	tagEndpoint = "WiadomosciUsuniete"
			case .sent:		tagEndpoint = "WiadomosciWyslane"
		}
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/\(tagEndpoint)")!)
		
		let body: [String: Any] = [
			"DataPoczatkowa": Int(startDate.timeIntervalSince1970),
			"DataKoncowa": Int(endDate.timeIntervalSince1970),
			"LoginId": user.userLoginID,
			"IdUczen": user.id,
		]
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
						  let objects = json["Data"] as? [[String: Any]] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return try JSONSerialization.data(withJSONObject: objects, options: [])
				}
				.decode(type: [Vulcan.Message].self, decoder: JSONDecoder())
				.sink(receiveCompletion: { (completion) in
					self.dataState.messages[tag]?.loading = false
					switch completion {
						case .finished:
							self.messages[tag] = tempMessages
							self.dataState.messages[tag]?.lastFetched = Date()
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { messages in
					logger.debug("Received \(messages.count) message(s).")
					
					let messages = messages
						.map { message -> Vulcan.Message in
							message.tag = tag
							return message
						}
						.sorted { $0.dateSent > $1.dateSent }
					
					tempMessages = messages
					
					if isPersistent {
						let context = self.persistentContainer.viewContext
						
						do {
							let oneMonthAgo: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: -1, to: Date()) ?? Date().startOfMonth
							let oneMonthInFuture: Date = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 1, to: Date()) ?? Date().endOfMonth
							
							let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoredMessage.fetchRequest()
							fetchRequest.predicate = NSPredicate(format: "dateSentEpoch <= %i OR dateSentEpoch >= %i", Int(oneMonthAgo.timeIntervalSince1970), Int(oneMonthInFuture.timeIntervalSince1970))
														
							switch (tag) {
								case .deleted:	fetchRequest.predicate = NSPredicate(format: "status == %@", "Usunieta")
								case .received:	fetchRequest.predicate = NSPredicate(format: "status == %@ AND folder == %@", "Widoczna", "Odebrane")
								case .sent:		fetchRequest.predicate = NSPredicate(format: "status == %@ AND folder == %@", "Widoczna", "Wyslane")
							}
							
							try context.execute(NSBatchDeleteRequest(fetchRequest: fetchRequest))
						} catch {
							logger.error("Error executing request: \(error.localizedDescription)")
						}
						
						for message in messages {
							_ = message.entity(context: context)
						}
						
						CoreDataModel.shared.saveContext()
					}
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			self.dataState.messages[tag]?.loading = false
			completionHandler(error)
		}
	}
	
	/// Moves a message to specified folder.
	/// - Parameters:
	///   - message: Message
	///   - folder: Folder to move the message to
	///   - completionHandler: Callback
	public func moveMessage(message: Vulcan.Message, to folder: Vulcan.MessageFolder, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Messages")
		logger.debug("Moving a message with ID \(message.id, privacy: .sensitive) to folder \"\(folder.rawValue)\"...")
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/ZmienStatusWiadomosci")!)
		
		let body: [String: Any] = [
			"WiadomoscId": message.id,
			"FolderWiadomosci": message.folder,
			"Status": folder.rawValue,
			"LoginId": user.userLoginID,
			"IdUczen": user.id,
		]
		
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data -> [String: Any] in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
										
					return json
				}
				.sink(receiveCompletion: { completion in
					switch completion {
						case .finished:
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { response in
					let success: Bool = (response["Status"] as? String ?? "").lowercased() == "ok"
					logger.debug("Received a response with status \"\(response["Status"] as? String ?? "<none>")\".")
					
					if success {
						switch folder {
							case .deleted:
								self.messages[message.tag ?? .received]?.removeAll(where: { $0.id == message.id })
								let message = message
								message.folder = folder.rawValue
								message.tag = .deleted
								self.messages[.deleted]?.append(message)
							case .read:		self.messages.flatMap(\.value).first(where: { $0.id == message.id })?.hasBeenRead = true
						}
						
						completionHandler(nil)
					} else {
						completionHandler(APIError.error(reason: response["Status"] as? String ?? "Unknown error"))
					}
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			completionHandler(error)
		}
	}
	
	/// Sends a new message to specified recipients.
	/// - Parameters:
	///   - recipients: Recipients
	///   - title: Message title
	///   - content: Message content
	///   - completionHandler: Callback
	public func sendMessage(to recipients: [Vulcan.Recipient], title: String, content: String, completionHandler: @escaping (Error?) -> () = { _  in }) {
		// Return if no user
		guard let user: Vulcan.Student = self.currentUser else {
			completionHandler(APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if no endpoint URL
		guard let endpointURL: String = self.endpointURL else {
			completionHandler(APIError.error(reason: "No endpoint"))
			return
		}
		
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Messages")
		logger.debug("Sending a message with title \(title, privacy: .sensitive) to recipients with ID(s) \(recipients.map(\.id))...")
		
		var request: URLRequest = URLRequest(url: URL(string: "\(endpointURL)\(user.reportingUnitSymbol)/mobile-api/Uczen.v3.Uczen/DodajWiadomosc")!)
		
		let body: [String: Any] = [
			"NadawcaWiadomosci": "\(user.surname) \(user.name)",
			"Tytul": title,
			"Tresc": content,
			"Adresaci": recipients.map { recipient in
				[
					"LoginId": recipient.id,
					"Nazwa": recipient.name
				]
			},
			"LoginId": user.userLoginID,
			"IdUczen": user.id,

		]
		
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyData
		
		do {
			try self.request(request)
				.receive(on: DispatchQueue.main)
				.tryMap { data -> [String: Any] in
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
						throw APIError.error(reason: "Error serializing JSON")
					}
					
					return json
				}
				.sink(receiveCompletion: { completion in
					switch completion {
						case .finished:
							completionHandler(nil)
						case .failure(let error):
							logger.error("\(error.localizedDescription)")
							completionHandler(error)
					}
				}, receiveValue: { response in
					let success: Bool = (response["Status"] as? String ?? "").lowercased() == "ok"
					logger.debug("Received a response with status \"\(response["Status"] as? String ?? "<none>")\".")
					
					completionHandler(success ? nil : APIError.error(reason: response["Status"] as? String ?? "Unknown error"))
				})
				.store(in: &cancellableSet)
		} catch {
			logger.error("\(error.localizedDescription)")
			completionHandler(error)
		}
	}
		
	// MARK: - Utilities
	
	/// Create and send API HTTP request.
	/// - Parameters:
	///   - request: URLRequest, modified inside
	///   - sign: Should we sign the data?
	/// - Returns: AnyPublisher<Data, Error>
	private func request(_ request: URLRequest, sign: Bool = true) throws -> AnyPublisher<Data, Error> {
		let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Request")
		
		// Check reachability
		if (self.monitor.currentPath.status != .satisfied) {
			logger.warning("Not reachable!")
			throw APIError.error(reason: "Not reachable")
		}
		
		// Modify request
		var modifiedRequest: URLRequest = request
		
		// Headers
		modifiedRequest.setValue("MobileUserAgent", forHTTPHeaderField: "User-Agent")
		modifiedRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
		modifiedRequest.setValue("close", forHTTPHeaderField: "Connection")
		modifiedRequest.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		// Body
		modifiedRequest.httpMethod = "POST"
		let timeNow: UInt64 = UInt64(floor(NSDate().timeIntervalSince1970))
		var body: [String: Any] = [
			"RemoteMobileTimeKey": timeNow,
			"TimeKey": (timeNow - 1),
			"RequestId": UUID().uuidString,
			"RemoteMobileAppVersion": "20.4.1.358",
			"RemoteMobileAppName": "VULCAN-iOS-ModulUcznia"
		]
		
		// Merge request bodies
		if let httpBody: Data = request.httpBody,
		   let oldRequestBody: [String: Any] = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
			body = body.merging(oldRequestBody) { (_, new) in new }
		}
		
		let bodyData = try? JSONSerialization.data(withJSONObject: body)
		modifiedRequest.httpBody = bodyData
		
		if sign {
			let requestParametersData: NSData = NSData(data: bodyData ?? Data())
			
			let password = "CE75EA598C7743AD9B0B7328DED85B06"
			guard let certificate: String = self.keychain["CertificatePfx"],
				  let decodedCert: Data = Data(base64Encoded: certificate) else {
				throw APIError.error(reason: "Error reading certificate")
			}
			
			do {
				let cert = try PKCS12(certificate: decodedCert, password: password)
				if let dataSignature: String = cert.signData(data: requestParametersData) {
					modifiedRequest.setValue(dataSignature, forHTTPHeaderField: "RequestSignatureValue")
					modifiedRequest.setValue(self.keychain["CertificateKey"] ?? "", forHTTPHeaderField: "RequestCertificateKey")
				}
			} catch {
				logger.error("Error importing certificate: \(error.localizedDescription)")
			}
		}
		
		// Send the request and pass it on
		return URLSession.shared.dataTaskPublisher(for: modifiedRequest)
			.mapError { $0 as Error }
			.map { $0.data }
			.eraseToAnyPublisher()
	}
	
	/// Schedules a task for supplied event.
	/// - Parameter event: Event to be notified about
	public func addScheduleEventNotification(_ event: Vulcan.ScheduleEvent) {
		let logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Notifications")
		logger.debug("Registering a new notification of event with title \"\(event.subjectName, privacy: .sensitive)\".")
		
		guard let dateStarts = event.dateStarts else {
			logger.debug("No `event.dateStarts`! Returning.")
			return
		}
		
		let content = UNMutableNotificationContent()
		content.title = event.subjectName
		
		if let employeeName = event.employee?.name,
		   let employeeSurname = event.employee?.surname {
			content.subtitle = "\(employeeName) \(employeeSurname)"
		} else {
			content.subtitle = "\(event.employeeID)"
		}
		
		if let dateEnds = event.dateEnds {
			content.body = "\(event.room) • \(dateStarts.formattedDateString(timeStyle: .short)) - \(dateEnds.formattedDateString(timeStyle: .short))"			
		}
		
		content.sound = UNNotificationSound.default
		content.categoryIdentifier = "ScheduleNotification"
		content.targetContentIdentifier = content.categoryIdentifier
		content.threadIdentifier = content.categoryIdentifier
		
		let identifier: String = "\(content.categoryIdentifier):\(event.dateStarts?.timeIntervalSinceReferenceDate ?? event.date.timeIntervalSinceReferenceDate):\(event.group ?? -1):\(event.subjectID)"
		
		let triggerDate: DateComponents
		let schedule = self.schedule
			.flatMap(\.events)
			.filter { $0.dateStarts ?? $0.date >= Date() }
			.filter { $0.isUserSchedule }
		
		if let itemIndex = schedule.firstIndex(of: event),
		   (itemIndex - 1) >= 0,
		   let dateEnds = schedule[itemIndex - 1].dateEnds,
		   Calendar.autoupdatingCurrent.isDate(schedule[itemIndex - 1].date, inSameDayAs: event.date) {
			triggerDate = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnds)
		} else {
			let date: Date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: -5, to: dateStarts) ?? dateStarts
			triggerDate = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		}
		
		let trigger: UNCalendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
		let request: UNNotificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				logger.warning("Couldn't add a notification with ID \(identifier, privacy: .sensitive): \(error.localizedDescription)")
			}
		}
	}
	
	/// Schedules a task for supplied event.
	/// - Parameter task: Task to be notified about
	/// - Parameter type: Type of exam
	public func addTaskNotification(_ task: VulcanTask, isBigType: Bool? = nil) {
		let logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Notifications")
		logger.debug("Registering a new notification of task with entry \"\(task.entry, privacy: .sensitive)\".")
		
		let content = UNMutableNotificationContent()
		
		switch (task.tag) {
			case .exam:
				if let isBigType = isBigType {
					content.title = "\(NSLocalizedString("Tomorrow", comment: "")): \(NSLocalizedString(isBigType ? "EXAM_BIG" : "EXAM_SMALL", comment: ""))"
				} else {
					content.title = "\(NSLocalizedString("Tomorrow", comment: "")): \(NSLocalizedString(task.tag.rawValue, comment: ""))"
				}
			case .homework:	content.title = NSLocalizedString("TASK_TOMORROW : TAG_HOMEWORK", comment: "")
		}
		
		if let subjectName = task.subject?.name {
			content.subtitle = subjectName
		} else {
			content.subtitle = "\(task.subjectID)"
		}
		
		
		content.body = task.entry
		content.sound = UNNotificationSound.default
		content.categoryIdentifier = "TaskNotification"
		content.targetContentIdentifier = content.categoryIdentifier
		content.threadIdentifier = content.categoryIdentifier
		
		let date: Date
		if let dayBefore: Date = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: task.date),
		   let finalDate: Date = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 9, to: dayBefore) {
			date = finalDate
		} else {
			date = task.date
		}
		
		let triggerDate: DateComponents = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		let trigger: UNCalendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
		let identifier: String = "\(content.categoryIdentifier):\(task.date.timeIntervalSinceReferenceDate):\(task.entry)"
		let request: UNNotificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				logger.warning("Couldn't add a notification with ID \(identifier, privacy: .sensitive): \(error.localizedDescription)")
			}
		}
	}
}

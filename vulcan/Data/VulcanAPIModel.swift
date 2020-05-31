//
//  APIModel.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Combine
import CoreData
import SwiftyJSON
import KeychainAccess

class VulcanAPIModel: ObservableObject {
	// MARK: - Private variables
	private let settings: SettingsModel = SettingsModel()
	private let ud: UserDefaults = UserDefaults.standard
	private let keychain: Keychain = Keychain(service: ("\(Bundle.main.bundleIdentifier ?? "vulcan")-\(UIDevice.current.name)" )).label("vulcan Certificate (\(UIDevice.current.name))").synchronizable(false).accessibility(.afterFirstUnlock)
	private let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
	private let dataContainer: NSPersistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
	private var coreDataContext: NSManagedObjectContext
	
	private var dictionary: VulcanDictionary?
	private var cancellableSet: Set<AnyCancellable> = []
	
	private var endpointURL: String {
		get { return ud.string(forKey: "endpointURL") ?? "" }
		set (value) { ud.set(value, forKey: "endpointURL") }
	}
	
	struct DataState {
		struct Status {
			var loading: Bool = false
			var fetched: Bool = false
			var lastFetched: Date = Date(timeIntervalSince1970: 0)
		}

		var grades: DataState.Status = DataState.Status()
		var schedule: DataState.Status = DataState.Status()
		var tasks: DataState.Status = DataState.Status()
		var messages: DataState.Status = DataState.Status()
		var eotGrades: DataState.Status = DataState.Status()
		var notes: DataState.Status = DataState.Status()
	}
	
	// MARK: - Public variables
	@Published var isLoggedIn: Bool = false
	@Published var dataState: DataState = DataState()
	
	@Published var users: [Vulcan.User] = []
	@Published var selectedUser: Vulcan.User?
	
	@Published var teachers: [Vulcan.Teacher] = []
	@Published var grades: [Vulcan.SubjectGrades] = []
	@Published var schedule: [Vulcan.Day] = []
	@Published var tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: [])
	@Published var messages: Vulcan.Messages = Vulcan.Messages(received: [], sent: [], deleted: [])
	@Published var notes: [Vulcan.Note] = []
	@Published var endOfTermGrades: Vulcan.TermGrades = Vulcan.TermGrades(anticipated: [], final: [])
	
	public var hasFirebaseToken: Bool {
		get {
			return self.keychain["FirebaseToken"] != nil && self.keychain["FirebaseToken"] != ""
		}
	}
	
	// MARK: - API Error
	enum APIError: Error, LocalizedError {
		case unknown
		case error(reason: String)
		
		var errorDescription: String? {
			switch self {
				case .unknown:
					return "Unknown error"
				case .error (let reason):
					return reason
			}
		}
	}
	
	// MARK: - init
	init() {
		print("[*] (VulcanAPI) init")
		self.coreDataContext = dataContainer.viewContext
		
		// Load cached data
		let vulcanStored = try? self.coreDataContext.fetch(VulcanStored.fetchRequest() as NSFetchRequest)
		if let stored: VulcanStored = vulcanStored?.last as? VulcanStored {
			let decoder = JSONDecoder()
			
			// Grades
			if let storedGrades = stored.grades {
				if let decoded = try? decoder.decode([Vulcan.SubjectGrades].self, from: storedGrades) {
					self.grades = decoded
					self.dataState.grades.fetched = true
				}
			}
			
			// Messages
			if let storedMessages = stored.messages {
				if let decoded = try? decoder.decode(Vulcan.Messages.self, from: storedMessages) {
					self.messages = decoded
					self.dataState.messages.fetched = true
				}
			}
			
			// EOT Grades
			if let storedEOTGrades = stored.eotGrades {
				if let decoded = try? decoder.decode(Vulcan.TermGrades.self, from: storedEOTGrades) {
					self.endOfTermGrades = decoded
					self.dataState.eotGrades.fetched = true
				}
			}
			
			// Notes
			if let storedNotes = stored.notes {
				if let decoded = try? decoder.decode([Vulcan.Note].self, from: storedNotes) {
					self.notes = decoded
					self.dataState.notes.fetched = true
				}
			}
			
			// Schedule
			if let storedSchedule = stored.schedule {
				if let decoded = try? decoder.decode([Vulcan.Day].self, from: storedSchedule) {
					self.schedule = decoded
					self.dataState.schedule.fetched = true
				}
			}
			
			// Tasks
			if let storedTasks = stored.tasks {
				if let decoded = try? decoder.decode(Vulcan.Tasks.self, from: storedTasks) {
					self.tasks = decoded
					self.dataState.tasks.fetched = true
				}
			}
		}
		
		// If we have the certificate, we're logged in
		if (self.keychain["CertificatePfx"] != nil) && (self.keychain["CertificatePfx"] != "") {
			// TODO: Validate token
			self.isLoggedIn = true
			UserDefaults.user.isLoggedIn = true
			print("[*] (VulcanAPI) Logged in: \(self.isLoggedIn) (Key: \(self.keychain["CertificateKey"] ?? "none"))")
		} else {
			print("[*] (VulcanAPI) Not logged in.")
			// Check for FirebaseToken
			if (self.keychain["FirebaseToken"] == nil || self.keychain["FirebaseToken"] == "") {
				print("[!] (VulcanAPI) No FirebaseToken! Registering...")
				self.registerFirebaseDevice()
			}
			self.logOut()
			return
		}
		
		// Load cached user
		do {
			let decoder = JSONDecoder()
			let data = try decoder.decode(Vulcan.User.self, from: UserDefaults.user.savedUserData ?? Data())
			self.selectedUser = data
		} catch {
			print("[!] (VulcanAPI) Error decoding savedUserData: \(error.localizedDescription)")
		}
		
		// Check reachability
		if (!appDelegate.isReachable) {
			print("[!] (VulcanAPI) Not reachable.")
			return
		}
		
		// Refresh users
		self.getUsers()
	}
	
	// MARK: - (Public) resetCancellable
	/// Resets the `cancellableSet` variable
	public func resetCancellable() {
		print("[!] (resetCancellable) Resetting cancellableSet.")
		self.cancellableSet.removeAll()
	}
	
	// MARK: - (Public) login
	/// Register new device and save received certificate.
	/// - Parameters:
	///   - token: 7 alphanumeric all-caps characters, which first three of them are the endpoint ID
	///   - symbol: Alphanumeric, lower-caps school symbol
	///   - pin: 6 numbers
	public func login(token: String, symbol: String, pin: Int, completionHandler: @escaping (Bool, Error?) -> (Void)) {
		// Get endpointURL based on our symbol
		URLSession.shared.dataTaskPublisher(for: URL(string: "http://komponenty.vulcan.net.pl/UonetPlusMobile/RoutingRules.txt")!)
			.receive(on: DispatchQueue.main)
			.tryMap { response in
				// Find endpointURL
				let lines = String(data: response.data, encoding: .utf8)?.split { $0.isNewline }
				var endpointURL: String?
				
				// Parse lines
				lines?.forEach { line in
					let items = line.split(separator: ",")
					if (String(items[0]) == String(token.prefix(3))) {
						// We found our URL
						endpointURL = String(items[1])
					}
				}
				
				if (endpointURL == nil) {
					throw APIError.error(reason: "No endpoint URL found!")
				}
				
				return endpointURL ?? ""
			}
			.flatMap { url in
				return self.getCertificate(url: url, token: token, symbol: symbol, pin: pin)
			}
			.tryMap { data in
				// Parse certificate
				do {
					let json: JSON = try JSON(data: data)
					
					// Check for errors
					if (json["IsError"].boolValue) {
						print("[!] (Certificate) IsError!")
						print(json)
						if (json["Message"].stringValue != "") {
						}
						throw APIError.error(reason: json["Message"].stringValue)
					}
										
					// Purge all saved data
					self.logOut()
					
					// Save certificate
					self.keychain["CertificatePfx"] = json["TokenCert"].dictionaryValue["CertyfikatPfx"]?.stringValue
					self.keychain["CertificateKey"] = json["TokenCert"].dictionaryValue["CertyfikatKlucz"]?.stringValue
					self.keychain["CertificateCreated"] = json["TokenCert"].dictionaryValue["CertyfikatDataUtworzenia"]?.stringValue
					self.keychain["Username"] = json["TokenCert"].dictionaryValue["UzytkownikNazwa"]?.stringValue ?? ""
					self.endpointURL = json["TokenCert"].dictionaryValue["AdresBazowyRestApi"]?.stringValue ?? ""
					
					print("[*] (Certificate) Parsed certificate! Key: \(self.keychain["CertificateKey"] ?? "").")
				} catch {
					// Error parsing
					print("[!] (Certificate) Error parsing: \(error.localizedDescription)")
					throw APIError.error(reason: "Error parsing certificate: \(error.localizedDescription)")
				}
			}
			.sink(receiveCompletion: { completion in
				print("[*] (Certificate) Completion: \(completion)")
				switch (completion) {
					case .failure(let error):
						print("[!] (Certificate) Error: \(error.localizedDescription)")
						self.logOut()
						completionHandler(false, error)
						break
					case .finished:
						// self.getDictionary()
						self.getUsers()
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { _ in })
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) logOut
	/// Log out, removing all stored data
	public func logOut() {
		print("[!] (Logout) Logging out!")
		// Keychain
		for key in self.keychain.allKeys() {
			print("[*] (Logout) Removing \"\(key)\" from Keychain.")
			self.keychain[key] = nil
		}
		print("[*] (Logout) Removing Keychain.")

		do {
			try self.keychain.remove((Bundle.main.bundleIdentifier ?? "vulcan"))
		} catch {
			print("[!] (Logout) Error removing Keychain: \(error.localizedDescription)")
		}
		
		// Variables
		self.endpointURL = ""
		self.isLoggedIn = false
		UserDefaults.user.isLoggedIn = false
		
		// CoreData
		do {
			try appDelegate.persistentContainer.viewContext.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "VulcanStored")))
			try appDelegate.persistentContainer.viewContext.execute(NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: "VulcanDictionary")))
		} catch {
			print("[!] (Logout) Error deleting stores: \(error).")
		}
		
		print("[*] (Logout) Done logging out.")
	}
	
	// MARK: - (Public) getUsers
	/// Get and parse available users
	public func getUsers() {
		// Check reachability
		if (!appDelegate.isReachable) {
			print("[!] (Users) Not reachable.")
			return
		}
		
		let request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)mobile-api/Uczen.v3.UczenStart/ListaUczniow")!)
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Users) Completion: \(completion)")
				switch (completion) {
					case .failure(let error):
						print("[!] (Users) Error: \(error.localizedDescription)")
						self.logOut()
						break
					case .finished:
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Certificate) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse users
					let responseUsers = json["Data"].arrayValue
					if (responseUsers.count > 0) {
						self.users = []
					}
					
					for user in responseUsers {
						self.users.append(self.parseUser(user))
					}
					
					print("[*] (Users) Found \(responseUsers.count) user(s).")
					if (self.users.count == 1) {
						self.setUser(self.users[0])
					}
				} catch {
					print("[!] (Users) Error parsing JSON: \(error.localizedDescription)")
					// self.logOut()
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) setUser
	/// Set default user
	/// - Parameter user: Selected VulcanUser
	public func setUser(_ user: Vulcan.User) {
		print("[!] (Users) Setting default user to \"\(user.UzytkownikNazwa)\" (\(user.id)).")
		self.selectedUser = user
		UserDefaults.user.isLoggedIn = true
		self.isLoggedIn = true
		self.getDictionary()
		
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(user)
			UserDefaults.user.savedUserData = data
		} catch {
			print("[!] (Users) Unable to encode userData: \(error)")
		}
	}
	
	// MARK: - (Public) getDictionary
	/// Fetches and saves dictionary
	public func getDictionary(force: Bool = false) {
		var storedDictionary = try? self.coreDataContext.fetch(VulcanDictionary.fetchRequest() as NSFetchRequest)
		if (storedDictionary?.count ?? 0 <= 0 || force) {
			// Fetch dictionary
			print("[*] (Dictionary) No dictionary saved.")
			
			// Return if no user
			guard let user: Vulcan.User = self.selectedUser else {
				return
			}
			
			let request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/Slowniki")!)
			print("[*] (Dictionary) Fetching new one...")
			self.request(request)
				.map { $0 }
				.sink(receiveCompletion: { completion in
					print("[*] (Dictionary) Completion: \(completion)")
					switch (completion) {
						case .failure(let error):
							print("[!] (Dictionary) Error: \(error.localizedDescription)")
							break
						case .finished:
							break
					}
				}, receiveValue: { value in
					do {
						let json: JSON = try JSON(data: value)
						
						// Check for error
						if (json["IsError"].boolValue) {
							print("[!] (Dictionary) IsError!")
							print(json)
							throw APIError.error(reason: json["Message"].stringValue)
						}
						
						// Parse dictionary
						let dictionary = json["Data"].dictionaryValue
						
						let employees: String? = dictionary["Pracownicy"]?.rawString(options: [])
						let gradeCategories: String? = dictionary["KategorieOcen"]?.rawString(options: [])
						let lastFetched: Date? = Date()
						let lessonTimes: String? = dictionary["PoryLekcji"]?.rawString(options: [])
						let noteCategories: String? = dictionary["KategorieUwag"]?.rawString(options: [])
						let presenceCategories: String? = dictionary["KategorieFrekwencji"]?.rawString(options: [])
						let presenceTypes: String? = dictionary["TypyFrekwencji"]?.rawString(options: [])
						let subjects: String? = dictionary["Przedmioty"]?.rawString(options: [])
						let teachers: String? = dictionary["Nauczyciele"]?.rawString(options: [])
						
						// Save dictionary to CoreData store
						let object = NSEntityDescription.insertNewObject(forEntityName: "VulcanDictionary", into: self.coreDataContext)
						object.setValue(employees, forKey: "employees")
						object.setValue(gradeCategories, forKey: "gradeCategories")
						object.setValue(lastFetched, forKey: "lastFetched")
						object.setValue(lessonTimes, forKey: "lessonTimes")
						object.setValue(noteCategories, forKey: "noteCategories")
						object.setValue(presenceCategories, forKey: "presenceCategories")
						object.setValue(presenceTypes, forKey: "presenceTypes")
						object.setValue(subjects, forKey: "subjects")
						object.setValue(teachers, forKey: "teachers")
						self.appDelegate.saveContext()
					} catch {
						print("[!] (Dictionary) Error parsing JSON: \(error.localizedDescription)")
					}
				})
				.store(in: &cancellableSet)
		} else {
			// More than one dictionary: Remove all but last
			if (storedDictionary?.count ?? 0 > 1) {
				print("[!] (Dictionary) More than one dictionary available: \(storedDictionary?.count ?? -1)")
				print(storedDictionary!)
				
				for i in 0...((storedDictionary?.count ?? 0) - 1) {
					if (i == storedDictionary?.count ?? 0 - 1) {
						return
					}
					
					print("[*] (Dictionary) Removing dictionary[\(i)]...")
					guard let toRemove: VulcanDictionary = storedDictionary?[i] as? VulcanDictionary else {
						return
					}
					coreDataContext.delete(toRemove as NSManagedObject)
				}
				
				self.appDelegate.saveContext()
			}
			
			storedDictionary = try? self.coreDataContext.fetch(VulcanDictionary.fetchRequest() as NSFetchRequest)
			
			// Check lastFetched
			if (storedDictionary?.count ?? 0 == 0) {
				print("[!] (Dictionary) No dictionary! Count: \(storedDictionary?.count ?? 0)")
				return
			}
			let storedVulcanDictionary: VulcanDictionary = storedDictionary?.last as! VulcanDictionary
			let lastFetched: Date = storedVulcanDictionary.lastFetched ?? Date(timeIntervalSince1970: 0)
			print("[*] (Dictionary) Dictionary available. Last fetched: \(lastFetched) (Age: \(Date(timeInterval: -(Date() - lastFetched), since: Date()).timestampString ?? "Unknown")).")
			
			// Check age
			let dictionaryAgePlusMonth: Date = Calendar.current.date(byAdding: .month, value: 1, to: lastFetched) ?? Date(timeIntervalSince1970: 0)
			if (dictionaryAgePlusMonth < Date()) {
				// Dictionary too old - fetch new one
				print("[!] (Dictionary) Dictionary too old. Removing and fetching new one...")
				storedDictionary?.removeAll()
				self.appDelegate.saveContext()
				self.getDictionary()
				return
			}
			
			// All good
			self.dictionary = storedVulcanDictionary
			
			// Parse teachers
			let savedTeachers: JSON = try! JSON(data: storedVulcanDictionary.teachers?.data(using: .utf8)! ?? Data())
			for teacher in savedTeachers.arrayValue {
				let newTeacher: Vulcan.Teacher = Vulcan.Teacher(
					id: teacher["Id"].intValue,
					name: teacher["Imie"].stringValue,
					surname: teacher["Nazwisko"].stringValue,
					code: teacher["Kod"].stringValue,
					active: teacher["Aktywny"].boolValue,
					teacher: teacher["Nauczyciel"].boolValue,
					loginID: teacher["LoginId"].intValue
				)
				self.teachers.append(newTeacher)
			}
			self.teachers = self.teachers.sorted(by: {$0.surname < $1.surname })
		}
	}
	
	// MARK: - (Public) getSchedule
	/// Get user's schedule
	/// - Parameter startDate: <#startDate description#>
	/// - Parameter endDate: <#endDate description#>
	/// - Parameter completionHandler: <#completionHandler description#>
	public func getSchedule(startDate: Date = Date(), endDate: Date = Date(), completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.schedule.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (Schedule) Getting schedule from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd"))...")
		self.dataState.schedule.loading = true

		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/PlanLekcjiZeZmianami")!)
		let body: [String: Any] = [
			"DataPoczatkowa": startDate.formattedString(format: "yyyy-MM-dd"),
			"DataKoncowa": endDate.formattedString(format: "yyyy-MM-dd"),
			"IdOddzial": user.IdOddzial,
			"IdOkresKlasyfikacyjny": user.IdOkresKlasyfikacyjny,
			"IdUczen": user.id,
			"LoginId": user.UzytkownikLoginId
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Schedule) Completion: \(completion)")
				self.dataState.schedule.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (Schedule) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.schedule.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Schedule) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse schedule
					if (json["Status"].stringValue == "Ok") {
						// Data is OK, parse events
						
						var tempSchedule: [Date: [Vulcan.Event]] = [:]
						
						let events = json["Data"].arrayValue
						for event in events {
							let date: Date = Date(timeIntervalSince1970: TimeInterval(event["Dzien"].intValue))
							
							// Lesson
							var lesson: Vulcan.Lesson
							guard let eventLesson: JSON = self.parseDictionary(tag: .lessonTimes, id: event["IdPoraLekcji"].intValue) else {
								// lesson = Vulcan.Lesson(id: 0, number: 0, startTime: 0, endTime: 0)
								print("[!] (Schedule) No lesson with id \(event["IdPoraLekcji"].intValue) found!")
								return
							}
							lesson = Vulcan.Lesson(id: eventLesson["Id"].intValue, number: eventLesson["Numer"].intValue, startTime: eventLesson["Poczatek"].intValue, endTime: eventLesson["Koniec"].intValue)
							
							// Teacher
							var teacher: Vulcan.Teacher
							guard let eventTeacher: JSON = self.parseDictionary(tag: .teachers, id: event["IdPracownik"].intValue) else {
								// teacher = Vulcan.Teacher(id: 0, name: "", surname: "", code: "", active: false, teacher: false, loginID: 0)
								print("[!] (Schedule) No teacher with id \(event["IdPracownik"].intValue) found!")
								return
							}
							teacher = Vulcan.Teacher(id: eventTeacher["Id"].intValue, name: eventTeacher["Imie"].stringValue, surname: eventTeacher["Nazwisko"].stringValue, code: eventTeacher["Kod"].stringValue, active: eventTeacher["Aktywny"].boolValue, teacher: eventTeacher["Nauczyciel"].boolValue, loginID: eventTeacher["LoginId"].intValue)
							
							// Subject
							var subject: Vulcan.Subject
							guard let eventSubject: JSON = self.parseDictionary(tag: .subjects, id: event["IdPrzedmiot"].intValue) else {
								// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
								print("[!] (Schedule) No subject with id \(event["IdPrzedmiot"].intValue) found!")
								return
							}
							subject = Vulcan.Subject(id: eventSubject["Id"].intValue, name: eventSubject["Nazwa"].stringValue, code: eventSubject["Kod"].stringValue, active: eventSubject["Aktywny"].boolValue, position: eventSubject["Pozycja"].intValue, teacher: teacher)
							
							let dateStarts: Date = Date(timeIntervalSince1970: TimeInterval(event["Dzien"].intValue + lesson.startTime + 3600))
							let dateEnds: Date = Date(timeIntervalSince1970: TimeInterval(event["Dzien"].intValue + lesson.endTime + 3600))
							
							// Create Event
							let newEvent: Vulcan.Event = Vulcan.Event(
								time: event["Dzien"].intValue,
								dateStarts: dateStarts,
								dateEnds: dateEnds,
								lessonOfTheDay: event["NumerLekcji"].intValue,
								lesson: lesson,
								subject: subject,
								group: event["PodzialSkrot"].string,
								room: event["Sala"].stringValue,
								teacher: teacher,
								note: event["AdnotacjaOZmianie"].stringValue,
								strikethrough: event["PrzekreslonaNazwa"].boolValue,
								bold: event["PogrubionaNazwa"].boolValue,
								userSchedule: event["PlanUcznia"].boolValue
							)
							
							if (tempSchedule[date] == nil) {
								tempSchedule[date] = []
							}
							
							tempSchedule[date]?.append(newEvent)
							/* if (event["PodzialSkrot"].string == nil) {
								// Not grouped
								tempSchedule[date]?.append(newEvent)
							} else {
								// Grouped
								if (UserDefaults.user.userGroup != 0) {
									// User specified group - show only user group
									if (event["PodzialSkrot"].stringValue == "\(UserDefaults.user.userGroup)/2" ) {
										tempSchedule[date]?.append(newEvent)
									}
								} else {
									// Not specified - don't show grouped
									tempSchedule[date]?.append(newEvent)
								}
							} */
						}
						
						// Sort and append
						var tempDays: [Vulcan.Day] = []
						for item in tempSchedule {
							tempSchedule[item.key] = tempSchedule[item.key]?.sorted(by: {
								return $0.lessonOfTheDay < $1.lessonOfTheDay
							})
							
							tempDays.append(Vulcan.Day(id: item.key, events: tempSchedule[item.key] ?? []))
						}
						
						// Sort the days of the schedule
						tempDays = tempDays.sorted(by: {
							return $0.id < $1.id
						})
						
						// Swap
						self.schedule = tempDays
						self.dataState.schedule.lastFetched = Date()
						
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.schedule)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "schedule", value: jsonData)
						self.appDelegate.saveContext()
						
						print("[*] (Schedule) Done parsing!")
					}
				} catch {
					print("[!] (Schedule) Error parsing JSON: \(error.localizedDescription)")
					// self.logOut()
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) getGrades
	/// Get current user's grades
	/// - Parameter completionHandler: <#completionHandler description#>
	public func getGrades(completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.grades.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (Grades) Getting grades for userID \(user.id)...")
		self.dataState.grades.loading = true
		let url: URL = URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/Oceny")!
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.IdOkresKlasyfikacyjny,
			"IdUczen": user.id
		]
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		
		var request: URLRequest = URLRequest(url: url)
		request.httpBody = bodyJson
				
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Grades) Completion: \(completion)")
				self.dataState.grades.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (Grades) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.grades.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Grades) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse
					if (json["Status"].stringValue == "Ok") {
						let grades = json["Data"].arrayValue
						
						var tempSubjectGrades: [Vulcan.Subject: [Vulcan.Grade]] = [:]
						
						for grade in grades {
							// Teacher
							var teacher: Vulcan.Teacher
							guard let eventTeacher: JSON = self.parseDictionary(tag: .teachers, id: grade["IdPracownikD"].intValue) else {
								print("[!] (Grades) No teacher with id \(grade["IdPracownikD"].intValue) found!")
								return
							}
							teacher = Vulcan.Teacher(id: eventTeacher["Id"].intValue, name: eventTeacher["Imie"].stringValue, surname: eventTeacher["Nazwisko"].stringValue, code: eventTeacher["Kod"].stringValue, active: eventTeacher["Aktywny"].boolValue, teacher: eventTeacher["Nauczyciel"].boolValue, loginID: eventTeacher["LoginId"].intValue)
							
							// Subject
							var subject: Vulcan.Subject
							guard let eventSubject: JSON = self.parseDictionary(tag: .subjects, id: grade["IdPrzedmiot"].intValue) else {
								print("[!] (Grades) No subject with id \(grade["IdPrzedmiot"].intValue) found!")
								return
							}
							subject = Vulcan.Subject(id: eventSubject["Id"].intValue, name: eventSubject["Nazwa"].stringValue, code: eventSubject["Kod"].stringValue, active: eventSubject["Aktywny"].boolValue, position: eventSubject["Pozycja"].intValue, teacher: teacher)
							
							// Grade Category
							var gradeCategory: Vulcan.GradeCategory?
							if let eventGradeCategory: JSON = self.parseDictionary(tag: .gradeCategories, id: grade["IdKategoria"].intValue, key: "Id") {
								gradeCategory = Vulcan.GradeCategory(id: eventGradeCategory["Id"].intValue, code: eventGradeCategory["Kod"].stringValue, name: eventGradeCategory["Nazwa"].stringValue)
							}
							
							let newGrade: Vulcan.Grade = Vulcan.Grade(
								id: grade["Id"].intValue,
								comment: grade["Komentarz"].string,
								description: grade["Opis"].stringValue,
								subjectID: subject.id,
								teacherID: teacher.id,
								date: Date(timeIntervalSince1970: TimeInterval(grade["DataUtworzenia"].intValue)),
								weight: grade["Waga"].doubleValue,
								value: grade["Wartosc"].double,
								categoryID: grade["IdKategoria"].intValue,
								weightModificator: grade["WagaModyfikatora"].doubleValue,
								entry: grade["Wpis"].stringValue,
								position: grade["Pozycja"].intValue,
								gradeWeight: grade["WagaOceny"].intValue,
								category: gradeCategory
							)
							
							if (tempSubjectGrades[subject] == nil) {
								tempSubjectGrades[subject] = []
							}
							
							tempSubjectGrades[subject]?.append(newGrade)
						}
						
						// Sort and append
						var tempGrades: [Vulcan.SubjectGrades] = []
						for item in tempSubjectGrades {
							tempSubjectGrades[item.key] = tempSubjectGrades[item.key]?.sorted(by: {
								return $0.date < $1.date
							})
							
							tempGrades.append(Vulcan.SubjectGrades(subject: item.key, grades: item.value))
						}
						
						// Sort the days of the schedule
						tempGrades = tempGrades.sorted(by: {
							return $0.subject.name < $1.subject.name
						})
						
						// Swap
						self.grades = tempGrades
						self.dataState.grades.lastFetched = Date()
						
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.grades)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "grades", value: jsonData)
						self.appDelegate.saveContext()
						
						print("[*] (Grades) Done parsing!")
					}
				} catch {
					print("[!] (Grades) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) getEOTGrades
	/// <#Description#>
	/// - Parameter completionHandler: <#completionHandler description#>
	public func getEOTGrades(completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.eotGrades.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (EOT Grades) Getting end of term grades of userID \(user.id)...")
		self.dataState.eotGrades.loading = true
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/OcenyPodsumowanie")!)
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.IdOkresKlasyfikacyjny,
			"IdUczen": user.id,
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (EOT Grades) Completion: \(completion)")
				self.dataState.eotGrades.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (EOT Grades) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.eotGrades.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (EOT Grades) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse
					if (json["Status"].stringValue == "Ok") {
						// let averages: [JSON] = json["Data"]["SrednieOcen"].arrayValue
						let anticipatedGrades: [JSON] = json["Data"]["OcenyPrzewidywane"].arrayValue
						let finalGrades: [JSON] = json["Data"]["OcenyKlasyfikacyjne"].arrayValue
						
						var tempAnticipated: [Vulcan.EndOfTermGrade] = []
						var tempFinal: [Vulcan.EndOfTermGrade] = []
						
						for grade in anticipatedGrades {
							// Subject
							var subject: Vulcan.Subject
							guard let eventSubject: JSON = self.parseDictionary(tag: .subjects, id: grade["IdPrzedmiot"].intValue) else {
								// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
								print("[!] (EOT Grades) No subject with id \(grade["IdPrzedmiot"].intValue) found!")
								return
							}
							subject = Vulcan.Subject(id: eventSubject["Id"].intValue, name: eventSubject["Nazwa"].stringValue, code: eventSubject["Kod"].stringValue, active: eventSubject["Aktywny"].boolValue, position: eventSubject["Pozycja"].intValue)
							
							tempAnticipated.append(Vulcan.EndOfTermGrade(grade: grade["Wpis"].intValue, subject: subject))
						}
						
						for grade in finalGrades {
							// Subject
							var subject: Vulcan.Subject
							guard let eventSubject: JSON = self.parseDictionary(tag: .subjects, id: grade["IdPrzedmiot"].intValue) else {
								// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
								print("[!] (EOT Grades) No subject with id \(grade["IdPrzedmiot"].intValue) found!")
								return
							}
							subject = Vulcan.Subject(id: eventSubject["Id"].intValue, name: eventSubject["Nazwa"].stringValue, code: eventSubject["Kod"].stringValue, active: eventSubject["Aktywny"].boolValue, position: eventSubject["Pozycja"].intValue)
							
							tempFinal.append(Vulcan.EndOfTermGrade(grade: grade["Wpis"].intValue, subject: subject))
						}
						
						tempAnticipated = tempAnticipated.sorted(by: { $0.subject.name < $1.subject.name })
						tempFinal = tempFinal.sorted(by: { $0.subject.name < $1.subject.name })
						self.endOfTermGrades = Vulcan.TermGrades(anticipated: tempAnticipated, final: tempFinal)
						self.dataState.eotGrades.lastFetched = Date()
						
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.endOfTermGrades)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "eotGrades", value: jsonData)
						self.appDelegate.saveContext()
					}
				} catch {
					print("[!] (EOT Grades) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) getTasks
	/// <#Description#>
	/// - Parameters:
	///   - startDate: <#startDate description#>
	///   - endDate: <#endDate description#>
	///   - completionHandler: <#completionHandler description#>
	public func getTasks(tag: Vulcan.TaskTag, startDate: Date = Date(), endDate: Date = Date(), completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.tasks.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (Tasks) Getting \"\(tag)\" from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd"))...")
		self.dataState.tasks.loading = true
		var tagEndpoint: String = ""
		switch (tag) {
			case .exam: tagEndpoint = "Sprawdziany"
			case .homework: tagEndpoint = "ZadaniaDomowe"
		}
		
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/\(tagEndpoint)")!)
		let body: [String: Any] = [
			"DataPoczatkowa": startDate.formattedString(format: "yyyy-MM-dd"),
			"DataKoncowa": endDate.formattedString(format: "yyyy-MM-dd"),
			"IdOddzial": user.IdOddzial,
			"IdOkresKlasyfikacyjny": user.IdOkresKlasyfikacyjny,
			"IdUczen": user.id,
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Tasks) Completion: \(completion)")
				self.dataState.tasks.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (Tasks) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.tasks.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Tasks) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse
					if (json["Status"].stringValue == "Ok") {
						let responseTasks = json["Data"].arrayValue
						var tempTasks: [Vulcan.Task] = []
						for task in responseTasks {
							// Teacher
							var teacher: Vulcan.Teacher
							guard let eventTeacher: JSON = self.parseDictionary(tag: .teachers, id: task["IdPracownik"].intValue) else {
								// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
								print("[!] (Tasks) No teacher with id \(task["IdPracownik"].intValue) found!")
								return
							}
							teacher = Vulcan.Teacher(id: eventTeacher["Id"].intValue, name: eventTeacher["Imie"].stringValue, surname: eventTeacher["Nazwisko"].stringValue, code: eventTeacher["Kod"].stringValue, active: eventTeacher["Aktywny"].boolValue, teacher: eventTeacher["Nauczyciel"].boolValue, loginID: eventTeacher["LoginId"].intValue)
							
							// Subject
							var subject: Vulcan.Subject
							guard let eventSubject: JSON = self.parseDictionary(tag: .subjects, id: task["IdPrzedmiot"].intValue) else {
								// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
								print("[!] (Tasks) No subject with id \(task["IdPrzedmiot"].intValue) found!")
								return
							}
							subject = Vulcan.Subject(id: eventSubject["Id"].intValue, name: eventSubject["Nazwa"].stringValue, code: eventSubject["Kod"].stringValue, active: eventSubject["Aktywny"].boolValue, position: eventSubject["Pozycja"].intValue, teacher: teacher)
							
							// Date
							let date: Date = Date(timeIntervalSince1970: TimeInterval(task["Data"].intValue))
							
							// Event
							let newExam: Vulcan.Task = Vulcan.Task(
								id: task["Id"].intValue,
								subject: subject,
								teacher: teacher,
								departmentID: task["IdOddzial"].intValue,
								groupID: task["IdPodzial"].int,
								groupName: task["PodzialNazwa"].string,
								groupShortName: task["PodzialSkrot"].string,
								typeID: task["RodzajNumer"].intValue,
								type: task["Rodzaj"].boolValue,
								description: task["Opis"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
								date: date,
								tag: tag
							)
							
							tempTasks.append(newExam)
							/* if (exam["PodzialSkrot"].string == nil) {
								// Not grouped
								tempExams.append(newExam)
							} else {
								// Grouped
								if (UserDefaults.user.userGroup != 0) {
									// User specified group - show only user group
									if (exam["PodzialSkrot"].stringValue == "\(UserDefaults.user.userGroup)/2" ) {
										tempExams.append(newExam)
									}
								} else {
									// Not specified - don't show grouped
									tempExams.append(newExam)
								}
							} */
						}
						
						tempTasks = tempTasks.sorted(by: { $0.date < $1.date })
						switch (tag) {
							case .exam:		self.tasks.exams = tempTasks; break;
							case .homework:	self.tasks.homework = tempTasks; break;
						}
						self.dataState.tasks.lastFetched = Date()
						
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.tasks)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "tasks", value: jsonData)
						self.appDelegate.saveContext()
					}
				} catch {
					print("[!] (Tasks) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) getMessages
	/// <#Description#>
	/// - Parameters:
	///   - tag: <#tag description#>
	///   - startDate: <#startDate description#>
	///   - endDate: <#endDate description#>
	///   - completionHandler: <#completionHandler description#>
	public func getMessages(tag: Vulcan.MessageTag, startDate: Date, endDate: Date, completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.messages.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (Messages) Getting messages from \(startDate.formattedString(format: "yyyy-MM-dd")) to \(endDate.formattedString(format: "yyyy-MM-dd")) with tag \"\(tag)\"...")
		self.dataState.messages.loading = true
		
		var tagEndpoint: String = ""
		switch (tag) {
			case .received:	tagEndpoint = "WiadomosciOdebrane"
			case .deleted:	tagEndpoint = "WiadomosciUsuniete"
			case .sent:		tagEndpoint = "WiadomosciWyslane"
		}
		let idTag: String = tag == .sent ? "" : "NadawcaId"
		
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/\(tagEndpoint)")!)
		
		let body: [String: Any] = [
			"DataPoczatkowa": Int(startDate.timeIntervalSince1970),
			"DataKoncowa": Int(endDate.timeIntervalSince1970),
			"LoginId": user.UzytkownikLoginId,
			"IdUczen": user.id,
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Messages) Completion: \(completion)")
				self.dataState.messages.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (Messages) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.messages.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)

					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Messages) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse
					if (json["Status"].stringValue == "Ok") {
						var tempMessages: [Vulcan.Message] = []
						
						let messages = json["Data"].arrayValue
						for message in messages {
							var senders: [Vulcan.Teacher] = []
							var hasBeenRead: Bool = false
							
							// Parse sender and hasBeenRead
							if (tag == .sent) {
								// Sender is actually a recipient
								let recipients = message["Adresaci"].arrayValue
								for recipient in recipients {
									guard let messageRecipient: JSON = self.parseDictionary(tag: .employees, id: recipient["LoginId"].intValue, key: "LoginId") else {
										// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
										print("[!] (Messages) No teacher with id \(recipient["LoginId"].intValue) found!")
										print(message)
										break
									}
									senders.append(Vulcan.Teacher(id: messageRecipient["Id"].intValue, name: messageRecipient["Imie"].stringValue, surname: messageRecipient["Nazwisko"].stringValue, code: messageRecipient["Kod"].stringValue, active: messageRecipient["Aktywny"].boolValue, teacher: messageRecipient["Nauczyciel"].boolValue, loginID: messageRecipient["LoginId"].intValue))
								}
								
								hasBeenRead = message["Przeczytane"].intValue == 1
							} else {
								// Sender is a teacher
								guard let messageSender: JSON = self.parseDictionary(tag: .employees, id: message[idTag].intValue, key: "LoginId") else {
									// subject = Vulcan.Subject(id: 0, name: "", code: "", active: false, position: 0)
									print("[!] (Messages) No teacher with id \(message[idTag].intValue) found!")
									print(message)
									break
								}
								senders.append(Vulcan.Teacher(id: messageSender["Id"].intValue, name: messageSender["Imie"].stringValue, surname: messageSender["Nazwisko"].stringValue, code: messageSender["Kod"].stringValue, active: messageSender["Aktywny"].boolValue, teacher: messageSender["Nauczyciel"].boolValue, loginID: messageSender["LoginId"].intValue))
								
								hasBeenRead = message["DataPrzeczytaniaUnixEpoch"].int != nil
							}
							
							var recipients: [String] = []
							for recipient in message["Adresaci"].arrayValue {
								recipients.append(recipient["Nazwa"].stringValue)
							}
														
							let newMessage: Vulcan.Message = Vulcan.Message(
								id: message["WiadomoscId"].intValue,
								senderID: message["NadawcaId"].intValue,
								senders: senders,
								recipients: recipients,
								title: message["Tytul"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
								content: message["Tresc"].stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
								sentDate: Date(timeIntervalSince1970: TimeInterval(message["DataWyslaniaUnixEpoch"].intValue)),
								readDate: Date(timeIntervalSince1970: TimeInterval(message["DataPrzeczytaniaUnixEpoch"].intValue)),
								status: message["StatusWiadomosci"].stringValue,
								folder: message["FolderWiadomosci"].stringValue,
								hasBeenRead: hasBeenRead,
								tag: tag
							)
							tempMessages.append(newMessage)
						}
						
						tempMessages = tempMessages.sorted(by: { $0.sentDate > $1.sentDate })
						switch (tag) {
							case .deleted:	self.messages.deleted = tempMessages; break
							case .received:	self.messages.received = tempMessages; break
							case .sent:		self.messages.sent = tempMessages; break
						}
						self.dataState.messages.lastFetched = Date()
												
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.messages)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "messages", value: jsonData)
						self.appDelegate.saveContext()
					}
				} catch {
					print("[!] (Messages) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) sendMessage
	/// <#Description#>
	/// - Parameters:
	///   - recipients: <#recipients description#>
	///   - messageTitle: <#messageTitle description#>
	///   - messageContent: <#messageContent description#>
	///   - completionHandler: <#completionHandler description#>
	public func sendMessage(recipients: [Vulcan.Teacher], messageTitle: String, messageContent: String, completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Validate message
		if (recipients.count == 0 || messageTitle.trimmingCharacters(in: .whitespacesAndNewlines) == "" || messageContent.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
			return
		}
		
		// DEBUG
		completionHandler(true, nil)
		
		print("[!] (Messages) Sending message as \"\(user.Imie) \(user.Nazwisko)\" to \"\(recipients)\" with title \"\(messageTitle.trimmingCharacters(in: .whitespacesAndNewlines))\"...")
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/DodajWiadomosc")!)
		
		var messageRecipients: [[String: Any]] = []
		recipients.forEach { recipient in
			messageRecipients.append(["LoginId": recipient.loginID, "Nazwa": "\(recipient.surname) \(recipient.name)"])
		}
		let body: [String: Any] = [
			"NadawcaWiadomosci": "\(user.Nazwisko) \(user.Imie)",
			"Tytul": messageTitle,
			"Tresc": messageContent,
			"Adresaci": messageRecipients,
			"LoginId": user.UzytkownikLoginId,
			"IdUczen": user.id
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		print(body)
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Messages) Completion: \(completion)")
				switch (completion) {
					case .failure(let error):
						print("[!] (Messages) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json = try JSON(data: value)
					if (json["Status"].stringValue == "Ok") {
						completionHandler(true, nil)
					} else {
						print("[!] (Messages) Error sending! Data: \(json)")
						completionHandler(false, nil)
					}
				} catch {
					print("[!] (Messages) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) moveMessage
	/// <#Description#>
	/// - Parameters:
	///   - messageID: <#messageID description#>
	///   - folder: <#folder description#>
	///   - completionHandler: <#completionHandler description#>
	public func moveMessage(messageID: Int, folder: Vulcan.MessageFolder, completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		print("[*] (Messages) Moving message with ID \(messageID) to \(folder.rawValue)...")
		
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/ZmienStatusWiadomosci")!)
		
		let body: [String: Any] = [
			"WiadomoscId": messageID,
			"FolderWiadomosci": "Odebrane",
			"Status": folder.rawValue,
			"LoginId": user.UzytkownikLoginId,
			"IdUczen": user.id,
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Messages) Completion: \(completion)")
				switch (completion) {
					case .failure(let error):
						print("[!] (Messages) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json = try JSON(data: value)
					if (json["Status"].stringValue == "Ok") {
						// Modify the local message
						if let index = self.messages.received.firstIndex(where: {$0.id == messageID}) {
							switch (folder) {
								case .deleted:	self.messages.received.remove(at: index); break
								case .read:		self.messages.received[index].hasBeenRead = true; break
							}
						}
						
						completionHandler(true, nil)
					} else {
						completionHandler(false, nil)
					}
				} catch {
					print("[!] (Messages) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) getNotes
	/// <#Description#>
	/// - Parameter completionHandler: <#completionHandler description#>
	public func getNotes(completionHandler: @escaping (Bool, Error?) -> () = { _, _  in }) {
		// Return if no user
		guard let user: Vulcan.User = self.selectedUser else {
			completionHandler(false, APIError.error(reason: "Not logged in"))
			return
		}
		
		// Return if already pending
		if (self.dataState.notes.loading) {
			completionHandler(true, nil)
			return
		}
		
		print("[*] (Notes) Getting notes of userID \(user.id)...")
		self.dataState.notes.loading = true
		var request: URLRequest = URLRequest(url: URL(string: "\(self.endpointURL)\(user.JednostkaSprawozdawczaSymbol)/mobile-api/Uczen.v3.Uczen/UwagiUcznia")!)
		let body: [String: Any] = [
			"IdOkresKlasyfikacyjny": user.IdOkresKlasyfikacyjny,
			"IdUczen": user.id,
		]
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		self.request(request)
			.map { $0 }
			.sink(receiveCompletion: { completion in
				print("[*] (Notes) Completion: \(completion)")
				self.dataState.notes.loading = false
				switch (completion) {
					case .failure(let error):
						print("[!] (Notes) Error: \(error.localizedDescription)")
						completionHandler(false, error)
						break
					case .finished:
						self.dataState.notes.fetched = true
						completionHandler(true, nil)
						break
				}
			}, receiveValue: { value in
				do {
					let json: JSON = try JSON(data: value)
					
					// Check for error
					if (json["IsError"].boolValue) {
						print("[!] (Notes) IsError!")
						print(json)
						throw APIError.error(reason: json["Message"].stringValue)
					}
					
					// Parse
					if (json["Status"].stringValue == "Ok") {
						var tempNotes: [Vulcan.Note] = []
						
						let notes = json["Data"].arrayValue
						for note in notes {
							let date: Date = Date(timeIntervalSince1970: TimeInterval(note["DataWpisu"].intValue))
							
							// Teacher
							var teacher: Vulcan.Teacher
							guard let eventTeacher: JSON = self.parseDictionary(tag: .teachers, id: note["IdPracownik"].intValue) else {
								print("[!] (Notes) No teacher with id \(note["IdPracownik"].intValue) found!")
								return
							}
							teacher = Vulcan.Teacher(id: eventTeacher["Id"].intValue, name: eventTeacher["Imie"].stringValue, surname: eventTeacher["Nazwisko"].stringValue, code: eventTeacher["Kod"].stringValue, active: eventTeacher["Aktywny"].boolValue, teacher: eventTeacher["Nauczyciel"].boolValue, loginID: eventTeacher["LoginId"].intValue)
							
							// Note Category
							var noteCategory: Vulcan.NoteCategory
							guard let eventNoteCategory: JSON = self.parseDictionary(tag: .noteCategories, id: note["IdKategoriaUwag"].intValue, key: "Id") else {
								print("[!] (Notes) No noteCategory with id \(note["IdKategoriaUwag"].intValue) found!")
								return
							}
							noteCategory = Vulcan.NoteCategory(id: eventNoteCategory["Id"].intValue, name: eventNoteCategory["Nazwa"].stringValue, active: eventNoteCategory["Aktywny"].boolValue)
							
							let newNote: Vulcan.Note = Vulcan.Note(
								id: note["Id"].intValue,
								content: note["TrescUwagi"].stringValue,
								date: date,
								userID: note["IdUczen"].intValue,
								teacher: teacher,
								category: noteCategory
							)
							tempNotes.append(newNote)
						}
						
						// Sort
						tempNotes = tempNotes.sorted(by: { $0.date < $1.date })
						self.notes = tempNotes
						self.dataState.notes.lastFetched = Date()
						
						// Save to VulcanStored
						let jsonEncoder = JSONEncoder()
						let jsonData = try jsonEncoder.encode(self.notes)
						self.appDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: "notes", value: jsonData)
						self.appDelegate.saveContext()
					}
				} catch {
					print("[!] (Notes) Error serializing JSON: \(error.localizedDescription)")
					print(value.base64EncodedString())
					completionHandler(false, error)
				}
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Public) parseDictionary
	/// <#Description#>
	/// - Parameters:
	///   - tag: <#tag description#>
	///   - id: <#id description#>
	/// - Returns: <#description#>
	public func parseDictionary(tag: Vulcan.DictionaryType, id: Int, key: String = "Id") -> JSON? {
		if (self.dictionary == nil) {
			self.getDictionary()
			return nil
		}
		
		let dictionary: VulcanDictionary = self.dictionary!
		var selectedProperty: String?
		
		switch (tag) {
			case .employees:				selectedProperty = dictionary.employees
			case .gradeCategories:			selectedProperty = dictionary.gradeCategories
			case .lessonTimes:				selectedProperty = dictionary.lessonTimes
			case .noteCategories:			selectedProperty = dictionary.noteCategories
			case .presenceCategories:		selectedProperty = dictionary.presenceCategories
			case .presenceTypes:			selectedProperty = dictionary.presenceTypes
			case .subjects:					selectedProperty = dictionary.subjects
			case .teachers:					selectedProperty = dictionary.teachers
		}
		
		let data = selectedProperty?.data(using: .utf8)!
		let json: JSON = try! JSON(data: data ?? Data())
		return json.array?.first(where: { $0[key].intValue == id })
	}
	
	// MARK: - (Public) request
	/// Create HTTP request
	/// - Parameters:
	///   - request: URLRequest, modified inside
	///   - signed: Should we sign the data?
	/// - Returns: AnyPublisher<Data, Error>
	public func request(_ req: URLRequest, signed: Bool = true) -> AnyPublisher<Data, Error> {
		// Check reachability
		if (!self.appDelegate.isReachable) {
			print("[!] (request) Not reachable!")
			self.appDelegate.sendNotification(NotificationData(autodismisses: true, dismissable: true, style: .normal, icon: "wifi.slash", title: "NO_CONNECTION_TITLE", subtitle: "NO_CONNECTION_SUBTITLE", expandedText: nil))
		}
		
		// Modify request
		var request: URLRequest = req
		
		// Headers
		request.setValue("MobileUserAgent", forHTTPHeaderField: "User-Agent")
		request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
		request.setValue("close", forHTTPHeaderField: "Connection")
		request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		// Body
		request.httpMethod = "POST"
		let timeNow: UInt64 = UInt64(floor(NSDate().timeIntervalSince1970))
		var body: [String: Any] = [
			"RemoteMobileTimeKey": timeNow,
			"TimeKey": (timeNow - 1),
			"RequestId": UUID().uuidString,
			"RemoteMobileAppVersion": "20.4.1.358",
			"RemoteMobileAppName": "VULCAN-iOS-ModulUcznia"
		]
		
		// Merge request bodies
		let reqBody = try? JSON(data: req.httpBody ?? Data()).dictionaryObject
		body = body.merging(reqBody ?? [:]) { (_, new) in new }
		
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		if (signed) {
			let requestParametersData: NSData = NSData(data: bodyJson ?? Data())
			
			let password = "CE75EA598C7743AD9B0B7328DED85B06"
			let encodedCert: Data = self.keychain["CertificatePfx"]?.data(using: .utf8) ?? Data()
			let decodedCert: Data = Data(base64Encoded: encodedCert) ?? Data()
			
			do {
				let cert = try PKCS12(data: decodedCert, password: password)
				let dataSignature: String = cert.signData(data: requestParametersData) ?? ""
				
				request.setValue(dataSignature, forHTTPHeaderField: "RequestSignatureValue")
				request.setValue(self.keychain["CertificateKey"] ?? "", forHTTPHeaderField: "RequestCertificateKey")
			} catch {
				print("[!] (Request) Error importing certificate: \(error.localizedDescription)")
			}
		}
		
		// Send the request and pass it
		return URLSession.shared.dataTaskPublisher(for: request)
			.receive(on: DispatchQueue.main)
			.mapError { $0 as Error }
			.map { $0.data }
			.eraseToAnyPublisher()
	}
	
	// MARK: - (Public) registerFirebaseDevice
	/// Register device in Firebase
	/// - Returns: Data and Error
	public func registerFirebaseDevice() {
		var request: URLRequest = URLRequest(url: URL(string: "https://android.googleapis.com/checkin")!)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-type")
		request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		let requestBody: [String: Any] = [
			"locale": "pl_PL",
			"digest": "",
			"checkin": [
				"iosbuild": [
					"model": UIDevice.current.name,
					"os_version": UIDevice.current.systemVersion
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
		
		request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
		
		URLSession.shared.dataTaskPublisher(for: request)
			.receive(on: DispatchQueue.main)
			.mapError { $0 as Error }
			.flatMap { self.getFirebaseToken(data: $0.data) }
			.sink(receiveCompletion: { completion in
				print("[*] (Firebase) Completion: \(completion)")
				switch (completion) {
					case .failure(let error):
						print("[!] (Firebase) Error: \(error.localizedDescription)")
						self.keychain["FirebaseToken"] = nil
						break
					case .finished:
						break
				}
			}, receiveValue: { value in
				let token: String? = String(data: value, encoding: .utf8)?.components(separatedBy: "token=").last
				if (token == nil) {
					print("[!] (Firebase) Token empty! Response: \"\(value.base64EncodedString())\"")
				}
				print("[*] (Firebase) Token: \(value)")
				self.keychain["FirebaseToken"] = token
			})
			.store(in: &cancellableSet)
	}
	
	// MARK: - (Private) getFirebaseToken
	/// <#Description#>
	/// - Parameter data: <#data description#>
	/// - Returns: <#description#>
	private func getFirebaseToken(data: Data) -> AnyPublisher<Data, Error> {
		var parsedJSON: JSON = JSON()
		if let json = try? JSON(data: data) {
			parsedJSON = json
		}
		
		var request: URLRequest = URLRequest(url: URL(string: "https://fcmtoken.googleapis.com/register")!)
		request.httpMethod = "POST"
		request.setValue("AidLogin \(parsedJSON["android_id"].intValue):\(parsedJSON["security_token"].intValue)", forHTTPHeaderField: "Authorization")
		request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
		
		let body: String = "device=\(parsedJSON["android_id"].intValue)&app=pl.vulcan.UonetMobileModulUcznia&sender=987828170337&X-subtype=987828170337&appid=dLIDwhjvE58&gmp_app_id=1:987828170337:ios:6b65a4ad435fba7f"
		request.httpBody = body.data(using: .utf8)
		
		return URLSession.shared.dataTaskPublisher(for: request)
			.receive(on: DispatchQueue.main)
			.mapError { $0 as Error }
			.map { $0.data }
			.eraseToAnyPublisher()
	}
	
	// MARK: - (Private) getCertificate
	/// Get certificate data, parse it and save it
	/// - Parameters:
	///   - url: Endpoint URL
	///   - token: Register token
	///   - symbol: Register symbol
	///   - pin: Register pin
	/// - Returns: Data and Error
	private func getCertificate(url: String, token: String, symbol: String, pin: Int) -> AnyPublisher<Data, Error> {
		// Start configuring request
		var request: URLRequest = URLRequest(url: URL(string: "\(url)/\(symbol)/mobile-api/Uczen.v3.UczenStart/Certyfikat")!)
		request.httpMethod = "POST"
		
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
			"DeviceName": "vulcan @ \(UIDevice.current.name)",
			"DeviceNameUser": UIDevice.current.name,
			"DeviceDescription": "",
			"DeviceSystemType": UIDevice.current.systemName,
			"DeviceSystemVersion": UIDevice.current.systemVersion,
			"TokenKey": token,
			"PIN": String(pin),
			"FirebaseTokenKey": self.keychain["FirebaseToken"] ?? ""
		]
		let bodyJson = try? JSONSerialization.data(withJSONObject: body)
		request.httpBody = bodyJson
		
		// Send the request and pass it
		return URLSession.shared.dataTaskPublisher(for: request)
			.receive(on: DispatchQueue.main)
			.mapError { $0 as Error }
			.map { $0.data }
			.eraseToAnyPublisher()
	}
	
	// MARK: - (Private) parseUser
	/// <#Description#>
	/// - Parameter json: <#json description#>
	/// - Returns: <#description#>
	private func parseUser(_ json: JSON) -> Vulcan.User {
		let parsedJSON: JSON = JSON(parseJSON: json.rawString(options: []) ?? "")
		
		let user: Vulcan.User = Vulcan.User(
			IdOkresKlasyfikacyjny:			parsedJSON["IdOkresKlasyfikacyjny"].intValue,
			OkresPoziom:					parsedJSON["OkresPoziom"].intValue,
			OkresNumer:						parsedJSON["OkresNumer"].intValue,
			IdJednostkaSprawozdawcza:		parsedJSON["IdJednostkaSprawozdawcza"].intValue,
			JednostkaSprawozdawczaNazwa:	parsedJSON["JednostkaSprawozdawczaNazwa"].stringValue,
			JednostkaSprawozdawczaSymbol:	parsedJSON["JednostkaSprawozdawczaSymbol"].stringValue,
			IdJednostka:					parsedJSON["IdJednostka"].intValue,
			JednostkaNazwa:					parsedJSON["JednostkaNazwa"].stringValue,
			JednostkaSkrot: 				parsedJSON["JednostkaSkrot"].stringValue,
			OddzialSymbol:					parsedJSON["OddzialSymbol"].stringValue,
			OddzialKod:						parsedJSON["OddzialKod"].stringValue,
			UzytkownikRola:					parsedJSON["UzytkownikRola"].stringValue,
			UzytkownikLogin:				parsedJSON["UzytkownikLogin"].stringValue,
			UzytkownikLoginId:				parsedJSON["UzytkownikLoginId"].intValue,
			UzytkownikNazwa:				parsedJSON["UzytkownikNazwa"].stringValue,
			id:								parsedJSON["Id"].intValue,
			IdOddzial:						parsedJSON["IdOddzial"].intValue,
			Imie:							parsedJSON["Imie"].stringValue,
			Imie2:							parsedJSON["Imie2"].stringValue,
			Nazwisko:						parsedJSON["Nazwisko"].stringValue,
			Pseudonim:						parsedJSON["Pseudonim"].stringValue,
			UczenPlec:						parsedJSON["UczenPlec"].intValue,
			Pozycja:						parsedJSON["Pozycja"].intValue,
			LoginId:						parsedJSON["LoginId"].int
		)
		
		return user
	}
}

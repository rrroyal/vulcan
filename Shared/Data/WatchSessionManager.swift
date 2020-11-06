//
//  WatchSessionManager.swift
//  WatchKit Extension
//
//  Created by royal on 08/09/2020.
//

import Foundation
import os
import WatchConnectivity
import CoreData
import Vulcan

/**
	WatchSessionManager payload:
	[
		"type": "InitData" / "Vulcan" / "DataRequest" / "MessageReceived"
		"requestedData": {type}	// only when type == "DataRequest"
		"payload": [String: Any]	// only when type == "Vulcan"
	]
*/

@available (iOS 14, watchOS 7, *)
public final class WatchSessionManager: NSObject, WCSessionDelegate {
	public static let shared = WatchSessionManager()
	public let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).WatchConnectivity", category: "WatchConnectivity")
	public let ud: UserDefaults = UserDefaults.group
	
	private override init() {
		super.init()
	}
	
	#if os(iOS)
	var initData: [String: Any] {
		get {
			[
				"type": "InitData",
				"payload": [
					UserDefaults.AppKeys.isLoggedIn.rawValue: ud.bool(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue),
					UserDefaults.AppKeys.colorScheme.rawValue: ud.string(forKey: UserDefaults.AppKeys.colorScheme.rawValue) ?? "Default",
					UserDefaults.AppKeys.colorizeGrades.rawValue: ud.bool(forKey: UserDefaults.AppKeys.colorizeGrades.rawValue)
				]
			]
		}
	}
	#endif
	
	// MARK: - Delegate functions
	
	/// Current session
	public let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
	
	/// Valid session
	public var validSession: WCSession? {
		// paired - the user has to have their device paired to the watch
		// watchAppInstalled - the user must have your watch app installed
		
		#if os(iOS)
		if let session = session, session.isPaired && session.isWatchAppInstalled {
			return session
		}
		#elseif os(watchOS)
		if let session = session {
			return session
		}
		#endif
		return nil
	}
	
	/// Starts the WCSession
	public func startSession() {
		session?.delegate = self
		session?.activate()
	}
	
	/// Called after session is started.
	/// - Parameters:
	///   - session: Current session
	///   - activationState: Session activation state
	///   - error: Error
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		self.logger.info("Session started.")
		
		#if os(iOS)
		self.sendMessage(initData)
		// update context
		#elseif os(watchOS)
		let message = [
			"type": "DataRequest",
			"requestedData": "InitData"
		]
		self.sendMessage(message)
		#endif
	}
	
	/// Called when the app received a message from the counterpart.
	/// - Parameters:
	///   - session: Current session
	///   - message: Received message
	///   - replyHandler: Code to run on a reply
	public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String: Any]) -> Void) {
		// Handle the request
		self.logger.info("Received a message! Keys: \(message.keys.joined(separator: ","), privacy: .private)")
		
		// Handle message
		self.handleMessage(message, replyHandler: replyHandler)
	}
	
	/// Called when the app received a message from the counterpart.
	/// - Parameters:
	///   - session: Current session
	///   - message: Received message
	public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		// Handle the request
		self.logger.info("Received a message! Keys: \(message.keys.joined(separator: ","), privacy: .private)")
		
		// Handle message
		self.handleMessage(message)
	}
	
	public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
		// Handle the request
		self.logger.info("Received user info! Keys: \(userInfo.keys.joined(separator: ","), privacy: .private)")
	}
	
	#if os(watchOS)
	/// Called when the app received an applicationContext from the counterpart.
	/// - Parameters:
	///   - session: Current session
	///   - applicationContext: Received context
	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		guard let payload = applicationContext["payload"] as? [String: Any],
			  applicationContext["type"] as? String ?? "" == "ApplicationContext" else {
			self.logger.warning("Invalid applicationContext!")
			return
		}
		
		// User
		if let data = payload["currentUser"] as? Data,
		   let user = try? JSONDecoder().decode(Vulcan.Student.self, from: data) {
			VulcanStore.shared.setUser(user)
		}
		
		// Schedule
		if let data = payload["schedule"] as? Data,
		   let schedule = try? JSONDecoder().decode([Vulcan.Schedule].self, from: data) {
			VulcanStore.shared.setSchedule(schedule)
		}
		
		// Grades
		if let data = payload["grades"] as? Data,
		   let grades = try? JSONDecoder().decode([Vulcan.SubjectGrades].self, from: data) {
			VulcanStore.shared.setGrades(grades)
		}
		
		// EOT Grades
		if let data = payload["eotGrades"] as? Data,
		   let eotGrades = try? JSONDecoder().decode([Vulcan.EndOfTermGrade].self, from: data) {
			VulcanStore.shared.setEOTGrades(eotGrades)
		}
		
		// Tasks
		if let data = payload["tasks"] as? Data,
		   let tasks = try? JSONDecoder().decode(Vulcan.Tasks.self, from: data) {
			VulcanStore.shared.setTasks(tasks)
		}
		
		// Messages
		if let data = payload["receivedMessages"] as? Data,
		   let messages = try? JSONDecoder().decode([Vulcan.Message].self, from: data) {
			VulcanStore.shared.setMessages(messages, tag: .received)
		}
		
		ud.setValue(Int(Date().timeIntervalSince1970), forKey: "lastSyncDate")
	}
	#endif
	
	// MARK: - Helper functions
	
	/// Send the data to the Watch counterpart.
	/// - Parameter data: Data to send
	/// - Throws: Error
	public func sendMessage(_ message: [String: Any]) {
		guard let session = validSession else {
			self.logger.error("No session!")
			return
		}
		
		self.logger.info("Sending data...")
		
		if session.isReachable {
			self.logger.info("Sending message! Reachable: \(session.isReachable), Type: \"\(message["type"] as? String ?? "<unknown>", privacy: .private)\".")
			
			session.sendMessage(message, replyHandler: { reply in
				self.logger.info("Reply: \(reply, privacy: .private)")
				
				self.handleMessage(message)
			}, errorHandler: { error in
				self.logger.error("Error sending a message: \(error.localizedDescription).")
			})
		} else {
			self.logger.warning("Session not reachable!")
		}		
	}
	
	/// Handles the received message.
	/// - Parameter message: Received message
	private func handleMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void = { _ in }) {
		guard let type = message["type"] as? String else {
			self.logger.error("No `type` in message! Message: \(message, privacy: .private)")
			replyHandler(["type": "MessageReceived"])
			return
		}
				
		switch type {
			case "MessageReceived":
				return
			
			case "DataRequest":
				guard let requestedData = message["requestedData"] as? String else {
					self.logger.warning("No \"requestedData\" in DataRequest!")
					break
				}
				
				#if os(iOS)
				switch requestedData {
					case "InitData":
						replyHandler(self.initData)
						return
						
					default:
						self.logger.warning("Unknown \"requestedData\": \(requestedData, privacy: .private)")
				}
			#endif
				
			#if os(watchOS)
			case "Vulcan":
				guard let payload = message["payload"] as? [String: Any] else {
					break
				}
				
				// Current user
				if let data = payload["currentUser"] as? Data,
				   let user = try? JSONDecoder().decode(Vulcan.Student.self, from: data) {
					VulcanStore.shared.setUser(user)
				}
				
				// Schedule
				if let data = payload["schedule"] as? Data,
				   let schedule = try? JSONDecoder().decode([Vulcan.Schedule].self, from: data) {
					VulcanStore.shared.setSchedule(schedule)
				}
				
				// Grades
				if let data = payload["grades"] as? Data,
				   let grades = try? JSONDecoder().decode([Vulcan.SubjectGrades].self, from: data) {
					VulcanStore.shared.setGrades(grades)
				}
				
				// EOT Grades
				if let data = payload["eotGrades"] as? Data,
				   let eotGrades = try? JSONDecoder().decode([Vulcan.EndOfTermGrade].self, from: data) {
					VulcanStore.shared.setEOTGrades(eotGrades)
				}
				
				// Tasks
				if let data = payload["tasks"] as? Data,
				   let tasks = try? JSONDecoder().decode(Vulcan.Tasks.self, from: data) {
					VulcanStore.shared.setTasks(tasks)
				}
				
				// Received Messages
				if let data = payload["receivedMessages"] as? Data,
				   let messages = try? JSONDecoder().decode([Vulcan.Message].self, from: data) {
					VulcanStore.shared.setMessages(messages, tag: .received)
				}
			#endif
				
			case "InitData":
				guard let payload = message["payload"] as? [String: Any] else {
					self.logger.warning("No payload in \"InitData\"!")
					break
				}
				
				for (key, value) in payload {
					self.logger.debug("Setting UD: \"\(key)\" = \"\(String(describing: value), privacy: .private)\"")
					ud.setValue(value, forKey: key)
				}
				
			case "Dictionary":
				guard let payload = message["payload"] as? [String: Any] else {
					self.logger.warning("No payload in \"Dictionary\"!")
					break
				}
				
				let context = CoreDataModel.shared.persistentContainer.viewContext
				
				let decoder = JSONDecoder()
				decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
				
				// Employees
				if let data = payload["employees"] as? Data {
					do {
						try context.execute(NSBatchDeleteRequest(fetchRequest: DictionaryEmployee.fetchRequest()))
						_ = try decoder.decode([DictionaryEmployee].self, from: data)
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
				}
				
				// Subjects
				if let data = payload["subjects"] as? Data {
					do {
						try context.execute(NSBatchDeleteRequest(fetchRequest: DictionarySubject.fetchRequest()))
						_ = try decoder.decode([DictionarySubject].self, from: data)
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
				}
				
				// Grade categories
				if let data = payload["gradeCategories"] as? Data {
					do {
						try context.execute(NSBatchDeleteRequest(fetchRequest: DictionaryGradeCategory.fetchRequest()))
						_ = try decoder.decode([DictionaryGradeCategory].self, from: data)
					} catch {
						logger.error("Error executing request: \(error.localizedDescription)")
					}
				}
				
				CoreDataModel.shared.saveContext()
				
			default:
				self.logger.warning("Unknown type: \"\(type, privacy: .private)\".")
		}
		
		replyHandler(["type": "MessageReceived"])
	}
	
	/// Updates application context.
	/// - Parameters:
	///   - user: `Vulcan.Student`
	///   - schedule: `[Vulcan.Schedule]`
	///   - grades: `[Vulcan.SubjectGrades]`
	///   - eotGrades: `[Vulcan.EndOfTermGrade]`
	///   - tasks: `Vulcan.Tasks`
	///   - receivedMessages: `[Vulcan.Message]`
	/// - Throws: Error
	public func updateApplicationContext(user: Vulcan.Student?, schedule: [Vulcan.Schedule], grades: [Vulcan.SubjectGrades], eotGrades: [Vulcan.EndOfTermGrade], tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: []), receivedMessages: [Vulcan.Message]) {
		self.logger.info("Updating application context...")
		
		do {
			let encoder: JSONEncoder = JSONEncoder()
			let message: [String: Any] = [
				"type": "ApplicationContext",
				"payload": [
					"currentUser": try encoder.encode(user),
					"schedule": try encoder.encode(schedule),
					"grades": try encoder.encode(grades),
					"eotGrades": try encoder.encode(eotGrades),
					"tasks": try encoder.encode(tasks),
					"receivedMessages": try encoder.encode(receivedMessages)
				]
			]
			
			self.sendMessage(message)
		} catch {
			self.logger.error("Error encoding: \(error.localizedDescription)")
		}
	}
}

#if os(iOS)
public extension WatchSessionManager {
	/// Called when session became inactive.
	/// - Parameter session: Current session
	func sessionDidBecomeInactive(_ session: WCSession) {
		self.logger.info("(WatchSessionManager) Session inactive.")
	}
	
	/// Called when session deactivated.
	/// - Parameter session: Current session
	func sessionDidDeactivate(_ session: WCSession) {
		self.logger.info("(WatchSessionManager) Session deactivated.")
	}
}
#endif

//
//  WatchSessionManager.swift
//  WatchKit Extension
//
//  Created by royal on 08/09/2020.
//

import Foundation
import os
import WatchConnectivity
import Vulcan

@available (iOS 14, watchOS 7, *)
public final class WatchSessionManager: NSObject, WCSessionDelegate {
	static public let shared = WatchSessionManager()
	public let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).WatchConnectivity", category: "WatchConnectivity")
	public let ud: UserDefaults = UserDefaults.group
	
	private override init() {
		super.init()
	}
	
	#if os(iOS)
	var initData: [String: Any] {
		get {
			[
				"type": "UserDefaults",
				"data": [
					UserDefaults.AppKeys.isLoggedIn.rawValue: ud.bool(forKey: UserDefaults.AppKeys.isLoggedIn.rawValue),
					UserDefaults.AppKeys.colorScheme.rawValue: ud.string(forKey: UserDefaults.AppKeys.colorScheme.rawValue) ?? "Default",
					UserDefaults.AppKeys.colorizeGrades.rawValue: ud.bool(forKey: UserDefaults.AppKeys.colorizeGrades.rawValue),
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
	
	/// Called after session is started
	/// - Parameters:
	///   - session: Current session
	///   - activationState: Session' activation state
	///   - error: Error
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		self.logger.info("Session started.")
		
		#if os(iOS)
		do {
			try self.sendData(initData)
			try self.updateApplicationContext(schedule: Vulcan.shared.schedule, grades: Vulcan.shared.grades, eotGrades: Vulcan.shared.eotGrades, tasks: Vulcan.shared.tasks, receivedMessages: Vulcan.shared.messages[.received] ?? [])
		} catch {
			self.logger.error("Error sending UserDefaults! Error: \(error.localizedDescription)")
		}
		#endif
	}
	
	/// Called when the app received a message from the counterpart
	/// - Parameters:
	///   - session: Current session
	///   - message: Received message
	///   - replyHandler: Code to run on a reply
	public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
		// Handle the request
		self.logger.info("Received a message!")
		replyHandler(["receivedData": true])
		
		// Prevent loop
		if (message["receivedData"] as? Bool ?? false == true) {
			return
		}
		
		// Handle message
		self.handleMessage(message)
	}
	
	/// Called when the app received an applicationContext from the counterpart
	/// - Parameters:
	///   - session: Current session
	///   - applicationContext: Received context
	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		if (applicationContext["receivedData"] as? Bool ?? false == true) {
			return
		}
		
		handleMessage(applicationContext)
	}
	
	// MARK: - Helper functions
	
	/// Send the data to the Watch counterpart.
	/// - Parameter data: Data to send
	/// - Throws: Error
	public func sendData(_ data: [String: Any]) throws {
		if let session = validSession {
			self.logger.info("Sending data...")

			do {
				if session.isReachable {
					self.logger.info("Sending message! Reachable: \(session.isReachable).")
					session.sendMessage(data, replyHandler: { reply in
						self.logger.info("Reply: \(reply)")
						if (reply["receivedData"] as? Bool ?? true == true) {
							return
						}
					}, errorHandler: { error in
						self.logger.error("Error sending a message: \(error.localizedDescription).")
					})
				} else {
					self.logger.warning("Session not reachable!")
				}
			}
			
			self.logger.info("Done sending data!")
		} else {
			self.logger.warning("No session!")
		}
	}
	
	/// Updates application context
	/// - Parameters:
	///   - schedule: `[Vulcan.Schedule]`
	///   - grades: `[Vulcan.SubjectGrades]`
	///   - eotGrades: `[Vulcan.EndOfTermGrade]`
	///   - tasks: `Vulcan.Tasks`
	///   - receivedMessages: `[Vulcan.Message]`
	/// - Throws: Error
	public func updateApplicationContext(schedule: [Vulcan.Schedule], grades: [Vulcan.SubjectGrades], eotGrades: [Vulcan.EndOfTermGrade], tasks: Vulcan.Tasks = Vulcan.Tasks(exams: [], homework: []), receivedMessages: [Vulcan.Message]) throws {
		self.logger.info("Updating application context...")
		
		let encoder: JSONEncoder = JSONEncoder()
		let data: [String: Any] = [
			"type": "Vulcan",
			"data": [
				"schedule": try encoder.encode(schedule),
				"grades": try encoder.encode(grades),
				"eotGrades": try encoder.encode(eotGrades),
				"tasks": try encoder.encode(tasks),
				"receivedMessages": try encoder.encode(receivedMessages)
			]
		]
		
		try self.sendData(data)
	}
	
	/// Handles the received message.
	/// - Parameter message: Received message
	public func handleMessage(_ message: [String: Any]) {
		guard let type: String = message["type"] as? String else {
			self.logger.warning("Unknown message: \(message)")
			return
		}
		
		switch type {
			#if os(iOS)
			// Request
			case "Request":
				if let requestedData = message["requestedData"] as? String,
				   requestedData == "initData" {
					try? self.sendData(initData)
				}
			#endif
				
			#if os(watchOS)
			// UserDefaults
			case "UserDefaults":
				if let data = message["data"] as? [String: Any] {
					for (key, value) in data {
						logger.debug("Setting \"\(key, privacy: .sensitive)\" to \"\(String(describing: value), privacy: .sensitive)\"!")
						ud.setValue(value, forKey: key)
					}
				}
			
			// Vulcan
			case "Vulcan":
				guard let data = message["data"] as? [String: Any] else {
					return
				}
				
				// Current user
				if let data = data["currentUser"] as? Data,
				   let user = try? JSONDecoder().decode(Vulcan.Student.self, from: data) {
					VulcanStore.shared.setUser(user)
				}
				
				// Schedule
				if let data = data["schedule"] as? Data,
				   let schedule = try? JSONDecoder().decode([Vulcan.Schedule].self, from: data) {
					VulcanStore.shared.setSchedule(schedule)
				}
				
				// Grades
				if let data = data["grades"] as? Data,
				   let grades = try? JSONDecoder().decode([Vulcan.SubjectGrades].self, from: data) {
					VulcanStore.shared.setGrades(grades)
				}
				
				// EOT Grades
				if let data = data["eotGrades"] as? Data,
				   let eotGrades = try? JSONDecoder().decode([Vulcan.EndOfTermGrade].self, from: data) {
					VulcanStore.shared.setEOTGrades(eotGrades)
				}
				
				// Tasks
				if let data = data["tasks"] as? Data,
				   let tasks = try? JSONDecoder().decode(Vulcan.Tasks.self, from: data) {
					VulcanStore.shared.setTasks(tasks)
				}
				
				// Received Messages
				if let data = data["receivedMessages"] as? Data,
				   let messages = try? JSONDecoder().decode([Vulcan.Message].self, from: data) {
					VulcanStore.shared.setMessages(messages, tag: .received)
				}
			#endif
				
			// Default
			default: break
		}
	}
}

#if os(iOS)
public extension WatchSessionManager {
	/// Called when session became inactive
	/// - Parameter session: Current session
	func sessionDidBecomeInactive(_ session: WCSession) {
		self.logger.info("(WatchSessionManager) Session inactive.")
	}
	
	/// Called when session deactivated
	/// - Parameter session: Current session
	func sessionDidDeactivate(_ session: WCSession) {
		self.logger.info("(WatchSessionManager) Session deactivated.")
	}
}
#endif

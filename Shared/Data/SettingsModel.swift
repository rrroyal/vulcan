//
//  SettingsModel.swift
//  vulcan
//
//  Created by royal on 15/03/2020.
//

import SwiftUI
import Foundation
import Combine
import os
import Vulcan

/// Model containing user settings data
final class SettingsModel: ObservableObject {
	static public let shared: SettingsModel = SettingsModel()
	
	// MARK: App data
	@AppStorage(UserDefaults.AppKeys.launchedBefore.rawValue, store: .group) public var launchedBefore: Bool = false
	@AppStorage(UserDefaults.AppKeys.isLoggedIn.rawValue, store: .group) public var isLoggedIn: Bool = false
	
	// MARK: User
	@AppStorage(UserDefaults.AppKeys.showAllScheduleEvents.rawValue, store: .group) public var showAllScheduleEvents: Bool = false
	@AppStorage(UserDefaults.AppKeys.readMessageOnOpen.rawValue, store: .group) public var readMessageOnOpen: Bool = true
	
	// MARK: Notifications
	@AppStorage(UserDefaults.AppKeys.enableScheduleNotifications.rawValue, store: .group) public var enableScheduleNotifications: Bool = false
	@AppStorage(UserDefaults.AppKeys.enableTaskNotifications.rawValue, store: .group) public var enableTaskNotifications: Bool = false
	
	// MARK: Interface
	@AppStorage(UserDefaults.AppKeys.filterSchedule.rawValue, store: .group) public var filterSchedule: Bool = false
	@AppStorage(UserDefaults.AppKeys.colorizeGrades.rawValue, store: .group) public var colorizeGrades: Bool = true
	@AppStorage(UserDefaults.AppKeys.colorScheme.rawValue, store: .group) public var colorScheme: String = "Default"
	@AppStorage(UserDefaults.AppKeys.hapticFeedback.rawValue, store: .group) public var hapticFeedback: Bool = true
	
	@Published public var updatesAvailable: Bool = false
	private var cancellableSet: Set<AnyCancellable> = []
	private let logger: Logger = Logger(subsystem: "Settings", category: "Settings")
	
	// MARK: - init
	private init() {
		// self.checkForUpdates()		
	}
	
	// MARK: - Public functions
	/// Resets the app' UserDefaults
	public func resetSettings() {
		logger.info("Resetting settings...")
		UserDefaults.standard.removePersistentDomain(forName: Bundle.main.groupIdentifier)
		Vulcan.shared.logOut()
		logger.info("Done resetting!")
	}
	
	/// Fetches the newest release on GitHub.
	/* public func checkForUpdates() {
		let currentVersion: String = Bundle.main.buildVersion
		let repoURL: URL = URL(string: "https://api.github.com/repos/rrroyal/vulcan/releases/latest")!
		
		var request: URLRequest = URLRequest(url: repoURL)
		request.httpMethod = "GET"
		
		// Check latest release
		logger.info("Checking latest release on GitHub (Local version: \(currentVersion))...")
		URLSession.shared.dataTaskPublisher(for: request)
			.receive(on: DispatchQueue.main)
			.mapError { $0 as Error }
			.map { $0.data }
			.sink(receiveCompletion:{ (completion) in
				switch (completion) {
					case .failure: self.logger.error("(Settings) Completion error: \(String(describing: completion))"); break
					case .finished: break
				}
			}, receiveValue: { (data) in
				do {
					let json: JSON = try JSON(data: data)
					if (json["tag_name"].stringValue.dropFirst() > currentVersion && !json["draft"].boolValue && json["target_commitish"].stringValue == "master") {
						self.logger.notice("New release available: \(json["tag_name"]).")
						self.updatesAvailable = true
					} else {
						self.logger.info("Already on latest version.")
					}
				} catch {
					self.logger.error("Error serializing JSON: \(error.localizedDescription)")
				}
			})
			.store(in: &cancellableSet)
	} */
}

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
	private let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Settings", category: "Settings")
	
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
}

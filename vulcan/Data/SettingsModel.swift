//
//  SettingsModel.swift
//  Harbour
//
//  Created by royal on 15/03/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import SwiftyJSON

/// Model containing user settings data
class SettingsModel: ObservableObject {
	@Published public var updatesAvailable: Bool = false
	@Published(key: "userGroup") public var userGroup: Int = UserDefaults.user.userGroup
	@Published(key: "readMessageOnOpen") public var readMessageOnOpen: Bool = UserDefaults.user.readMessageOnOpen
	@Published(key: "hapticFeedback") public var hapticFeedback: Bool = UserDefaults.user.hapticFeedback
	@Published(key: "colorScheme") public var colorScheme: String = UserDefaults.user.colorScheme
	@Published(key: "colorizeGrades") public var colorizeGrades: Bool = UserDefaults.user.colorizeGrades
	@Published(key: "colorizeGradeBackground") public var colorizeGradeBackground: Bool = UserDefaults.user.colorizeGradeBackground
	
	@Published var isNotificationVisible: Bool = false
	@Published var notificationData: NotificationData?
	var notificationPublisher = PassthroughSubject<Bool, Never>()
	
	public func resetSettings() {
		print("[!] Resetting settings!")
		UserDefaults.standard.removeObject(forKey: "launchedBefore")
		let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
		UserDefaults.standard.synchronize()
	}
}

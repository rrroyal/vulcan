//
//  UserDefaults.swift
//  
//
//  Created by royal on 23/07/2020.
//

import Foundation

public extension UserDefaults {
	enum AppKeys: String {
		case launchedBefore = "launchedBefore"
		case isLoggedIn = "isLoggedIn"
		case readMessageOnOpen = "readMessageOnOpen"
		case enableScheduleNotifications = "enableScheduleNotifications"
		case enableTaskNotifications = "enableTaskNotifications"
		case colorizeGrades = "colorizeGrades"
		case hapticFeedback = "hapticFeedback"
		case showAllScheduleEvents = "showAllScheduleEvents"
		case colorScheme = "colorScheme"
		case dictionaryLastFetched = "dictionaryLastFetched"
		case userID = "userID"
		case filterSchedule = "filterSchedule"
	}
	
	static let group = UserDefaults(suiteName: "group.dev.niepostek.vulcanGroup")!
}

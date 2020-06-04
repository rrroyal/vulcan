//
//  UserDefaults.swift
//  vulcan
//
//  Created by royal on 08/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension UserDefaults {
	static let group = UserDefaults(suiteName: Bundle.main.object(forInfoDictionaryKey: "GroupIdentifier") as? String ?? "")!
	
	struct user {
		static var launchedBefore: Bool {
			get { return UserDefaults.group.bool(forKey: "launchedBefore") }
			set { UserDefaults.group.set(newValue, forKey: "launchedBefore") }
		}
		
		static var isLoggedIn: Bool {
			get { return UserDefaults.group.bool(forKey: "isLoggedIn") }
			set { UserDefaults.group.set(newValue, forKey: "isLoggedIn") }
		}
		
		static var userGroup: Int {
			get { return UserDefaults.group.integer(forKey: "userGroup") }
			set { UserDefaults.group.set(newValue, forKey: "userGroup") }
		}
		
		static var savedUserData: Data? {
			get { return UserDefaults.group.data(forKey: "savedUserData") }
			set { UserDefaults.group.set(newValue, forKey: "savedUserData") }
		}
		
		static var readMessageOnOpen: Bool {
			get { return UserDefaults.group.bool(forKey: "readMessageOnOpen") }
			set { UserDefaults.group.set(newValue, forKey: "readMessageOnOpen") }
		}
		
		static var hapticFeedback: Bool {
			get { return UserDefaults.group.bool(forKey: "hapticFeedback") }
			set { UserDefaults.group.set(newValue, forKey: "hapticFeedback") }
		}
		
		static var colorScheme: String {
			get { return UserDefaults.group.string(forKey: "colorScheme") ?? "Default" }
			set { UserDefaults.group.set(newValue, forKey: "colorScheme") }
		}
		
		static var colorizeGrades: Bool {
			get { return UserDefaults.group.bool(forKey: "colorizeGrades") }
			set { UserDefaults.group.set(newValue, forKey: "colorizeGrades") }
		}
		
		static var colorizeGradeBackground: Bool {
			get { return UserDefaults.group.bool(forKey: "colorizeGradeBackground") }
			set { UserDefaults.group.set(newValue, forKey: "colorizeGradeBackground") }
		}
	}
}

//
//  UserDefaults.swift
//  vulcan
//
//  Created by royal on 08/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension UserDefaults {
	struct user {
		static var launchedBefore: Bool {
			get { return UserDefaults.standard.bool(forKey: "launchedBefore") }
			set { UserDefaults.standard.set(newValue, forKey: "launchedBefore") }
		}
		
		static var isLoggedIn: Bool {
			get { return UserDefaults.standard.bool(forKey: "isLoggedIn") }
			set { UserDefaults.standard.set(newValue, forKey: "isLoggedIn") }
		}
		
		static var userGroup: Int {
			get { return UserDefaults.standard.integer(forKey: "userGroup") }
			set { UserDefaults.standard.set(newValue, forKey: "userGroup") }
		}
		
		static var savedUserData: Data? {
			get { return UserDefaults.standard.data(forKey: "savedUserData") }
			set { UserDefaults.standard.set(newValue, forKey: "savedUserData") }
		}
		
		static var readMessageOnOpen: Bool {
			get { return UserDefaults.standard.bool(forKey: "readMessageOnOpen") }
			set { UserDefaults.standard.set(newValue, forKey: "readMessageOnOpen") }
		}
		
		static var hapticFeedback: Bool {
			get { return UserDefaults.standard.bool(forKey: "hapticFeedback") }
			set { UserDefaults.standard.set(newValue, forKey: "hapticFeedback") }
		}
		
		static var colorScheme: String {
			get { return UserDefaults.standard.string(forKey: "colorScheme") ?? "Default" }
			set { UserDefaults.standard.set(newValue, forKey: "colorScheme") }
		}
		
		static var colorizeGrades: Bool {
			get { return UserDefaults.standard.bool(forKey: "colorizeGrades") }
			set { UserDefaults.standard.set(newValue, forKey: "colorizeGrades") }
		}
		
		static var colorizeGradeBackground: Bool {
			get { return UserDefaults.standard.bool(forKey: "colorizeGradeBackground") }
			set { UserDefaults.standard.set(newValue, forKey: "colorizeGradeBackground") }
		}
	}
}

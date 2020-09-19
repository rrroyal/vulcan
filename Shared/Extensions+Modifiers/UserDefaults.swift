//
//  UserDefaults.swift
//  vulcan
//
//  Created by royal on 08/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension UserDefaults {	
	public var colorScheme: String {
		get { return UserDefaults.group.string(forKey: "colorScheme") ?? "Default" }
		set (value) { UserDefaults.group.set(value, forKey: "colorScheme") }
	}
}

//
//  Bundle.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

extension Bundle {
	public var buildVersion: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}
	
	public var buildNumber: String {
		return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	}
	
	public var colorSchemes: [String] {
		return ["Default", "Dzienniczek+"]
	}	
}

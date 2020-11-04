//
//  Bundle.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import UIKit

extension Bundle {
	public var buildVersion: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}
	
	public var buildNumber: String {
		Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	}
	
	public var colorSchemes: [String] {
		["Default", "Dzienniczek+"]
	}
	
	public var appIcons: [String] {
		["Default", "Dark"]
	}
	
	public var currentAppIconName: String {
		UIApplication.shared.alternateIconName ?? "Default"
	}
	
	public var currentAppIconImage: UIImage? {
		if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
		   let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
		   let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
		   let lastIcon = iconFiles.last {
			return UIImage(named: lastIcon)
		}
		return nil
	}
	
	public var groupIdentifier: String {
		"group.dev.niepostek.vulcanGroup"
	}
}

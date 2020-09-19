//
//  Bundle.swift
//  Vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

#if os(watchOS)
import WatchKit
#endif

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

import Foundation

public extension Bundle {
	var buildVersion: String {
		return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}
	
	var buildNumber: String {
		return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
	}
	
	var modelName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().model
		#elseif os(OSX)
		return ProcessInfo().hostName
		#else
		return UIDevice.current.model
		#endif
	}
	
	var deviceName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().name
		#elseif os(OSX)
		return ProcessInfo().hostName
		#else
		return UIDevice.current.name
		#endif
	}
	
	var systemName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().systemName
		#elseif os(OSX)
		return "macOS"
		#else
		return UIDevice.current.systemName
		#endif
	}
	
	var systemVersion: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().systemVersion
		#elseif os(OSX)
		let version = ProcessInfo().operatingSystemVersion
		return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
		#else
		return UIDevice.current.systemVersion
		#endif
	}
}

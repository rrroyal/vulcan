//
//  DeviceInfo.swift
//  vulcan
//
//  Created by royal on 05/04/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

#if os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#else
import UIKit
#endif

struct DeviceInfo {
	static var supportsHapticsOrVibration: Bool {
		#if os(macOS)
		return false
		#elseif os(iOS)
		return UIDevice.current.userInterfaceIdiom == .phone
		#elseif os(watchOS)
		return true
		#endif
	}
	
	static var modelName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().model
		#else
		return UIDevice.current.model
		#endif
	}
	
	static var deviceName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().name
		#else
		return UIDevice.current.name
		#endif
	}
	
	static var systemName: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().systemName
		#else
		return UIDevice.current.systemName
		#endif
	}
	
	static var systemVersion: String {
		#if os(watchOS)
		return WKInterfaceDevice.current().systemVersion
		#else
		return UIDevice.current.systemVersion
		#endif
	}
}

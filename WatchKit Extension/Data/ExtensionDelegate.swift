//
//  ExtensionDelegate.swift
//  WatchKit Extension
//
//  Created by royal on 08/09/2020.
//

import Foundation
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
	func applicationDidFinishLaunching() {
		WatchSessionManager.shared.startSession()
	}
}

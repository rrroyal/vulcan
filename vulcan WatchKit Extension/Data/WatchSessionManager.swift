//
//  WatchSessionManager.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import WatchConnectivity
import WatchKit

class WatchSessionManager: NSObject, WCSessionDelegate {
	static let shared = WatchSessionManager()
	
	private override init() {
		super.init()
	}
	
	private let extensionDelegate: ExtensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
	private let session: WCSession = WCSession.default
	
	/// Starts the session
	func startSession() {
		session.delegate = self
		session.activate()
	}
	
	/// Called after session is started
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("[*] (WatchSessionManager) Session started.")
	}
	
	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		print("[!] (WatchSessionManager) Received data: \(applicationContext.keys)")
		switch (applicationContext["type"] as! String) {
			case "coreData":
				extensionDelegate.createOrUpdate(forEntityName: "VulcanStored", forKey: applicationContext["key"] as! String, value: applicationContext["value"] as! Data)
			case "userDefaults":
				applicationContext.keys.forEach { key in
					if (key == "type") {
						return
					}
					print("[*] (UserDefaults) Setting \"\(key)\" to \"\(applicationContext[key] ?? "")\"")
					UserDefaults.group.set(applicationContext[key], forKey: key)
				}
			default: break
		}
		extensionDelegate.saveContext()
	}
}

//
//  WatchSessionManager.swift
//  vulcan
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
	static let shared = WatchSessionManager()
	
	private override init() {
		super.init()
	}
	
	/// <#Description#>
	private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
	
	/// Valid session
	private var validSession: WCSession? {
		// paired - the user has to have their device paired to the watch
		// watchAppInstalled - the user must have your watch app installed
		
		// Note: if the device is paired, but your watch app is not installed
		// consider prompting the user to install it for a better experience
		
		if let session = session, session.isPaired && session.isWatchAppInstalled {
			return session
		}
		return nil
	}
	
	/// Starts the WCSession
	func startSession() {
		session?.delegate = self
		session?.activate()
	}
	
	/// Called after session is started
	/// - Parameters:
	///   - session: <#session description#>
	///   - activationState: <#activationState description#>
	///   - error: <#error description#>
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("[*] (WatchSessionManager) Session started.")
		do {
			try updateApplicationContext(applicationContext: ["isLoggedIn": UserDefaults.user.isLoggedIn, "userGroup": UserDefaults.user.userGroup, "colorScheme": UserDefaults.user.colorScheme, "colorizeGrades": UserDefaults.user.colorizeGrades, "type": "userDefaults"])
		} catch {
			print("[!] (WatchSessionManager) Error sending UserDefaults! Error: \(error)")
		}
	}
	
	/// Called when session became inactive
	/// - Parameter session: <#session description#>
	func sessionDidBecomeInactive(_ session: WCSession) {
		print("[*] (WatchSessionManager) Session inactive.")
	}
	
	/// Called when session deactivated
	/// - Parameter session: <#session description#>
	func sessionDidDeactivate(_ session: WCSession) {
		print("[*] (WatchSessionManager) Session deactivated.")
	}
	
	/// <#Description#>
	/// - Parameter applicationContext: <#applicationContext description#>
	/// - Throws: <#description#>
	func updateApplicationContext(applicationContext: [String: Any]) throws {
		if let session = validSession {
			do {
				print("[*] (WatchSessionManager) Sending data! Reachable: \(session.isReachable).")
				if (session.isReachable) {
					session.transferUserInfo(applicationContext)
				} else {
					try session.updateApplicationContext(applicationContext)
				}
			} catch {
				print("[*] (WatchSessionManager) Error: \(error)")
				throw error
			}
		} else {
			print("[*] (WatchSessionManager) No valid session.")
		}
	}
}

//
//  Notifications.swift
//  vulcan
//
//  Created by royal on 09/07/2020.
//

import UIKit
import Foundation
import UserNotifications
import os

final class Notifications: NSObject, UNUserNotificationCenterDelegate {
	public static var shared: Notifications = Notifications()
	public var notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()
	
	public let logger: Logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).Vulcan", category: "Notifications")
	
	private override init() {
		super.init()
	}
	
	// MARK: - Delegate functions
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.banner])
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		completionHandler()
	}
	
	// MARK: - Helper functions
	
	/// Requests the authorization for notifications.
	func requestAuthorization() {
		let options: UNAuthorizationOptions = [.alert, .sound, .badge, .announcement]
		
		notificationCenter.requestAuthorization(options: options) { (allowed, error) in
			if !allowed {
				self.logger.warning("User declined the authorization prompt. Error: \(error?.localizedDescription ?? "none")")
				return
			}
			
			DispatchQueue.main.async {
				self.logger.debug("Registering for APNs.")
				UIApplication.shared.registerForRemoteNotifications()
			}
		}
	}
}

//
//  AppState.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Combine
import Network
import BackgroundTasks
import NotificationCenter
import os

final class AppState: ObservableObject {
	static public var shared: AppState = AppState()
	static public var networking: AppState.Networking = AppState.Networking()
	
	public var shortcutItemToProcess: UIApplicationShortcutItem?
	@Published public var currentTab: [Tab] = [.home]
	
	private let logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).AppState", category: "AppState")
	
	private init() {
		logger.debug("Initialized")
		AppState.networking.monitor.start(queue: .global(qos: .background))
		
		NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: .NSProcessInfoPowerStateDidChange, object: nil)
	}
	
	// MARK: - Networking
	/// Networking
	public class Networking {
		private var launchedBefore: Bool = false
		
		fileprivate init() {
			// self.monitor.start(queue: .global())
			self.monitor.pathUpdateHandler = { path in
				// Publish
				self.notificationPublisher.send(path.status == .satisfied)
				
				if (self.monitor.queue == nil || !self.launchedBefore) {
					return
				}
				
				// Check if connection is reachable
				/* if (path.status == .satisfied) {
					// Yes - send a notification about it
					let notificationData: NotificationData = NotificationData(
						autodismisses: true,
						dismissable: true,
						style: .normal,
						icon: "wifi",
						title: "CONNECTION_AVAILABLE_TITLE",
						subtitle: "CONNECTION_AVAILABLE_SUBTITLE",
						expandedText: nil
					)
					AppState.notifications.sendNotification(notificationData)
				} else {
					// No - send a notification about it
					let notificationData: NotificationData = NotificationData(
						autodismisses: true,
						dismissable: true,
						style: .normal,
						icon: "wifi.slash",
						title: "NO_CONNECTION_TITLE",
						subtitle: "NO_CONNECTION_SUBTITLE",
						expandedText: nil
					)
					AppState.notifications.sendNotification(notificationData)
				} */
			}
		}
		
		public var notificationPublisher = PassthroughSubject<Bool, Never>()
		public let monitor: NWPathMonitor = NWPathMonitor()
		public var isReachable: Bool? {
			get {				
				if (self.monitor.queue == nil) {
					return nil
				}
				
				return monitor.currentPath.status == .satisfied
			}
		}
	}
	
	// MARK: Other
	@Published public var isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled
	@objc func powerStateChanged(_ notification: Notification) {
		DispatchQueue.main.async {
			self.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
		}
	}
}

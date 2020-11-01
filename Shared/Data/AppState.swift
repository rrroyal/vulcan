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
	
	// Private variables
	private let logger = Logger(subsystem: "\(Bundle.main.bundleIdentifier!).AppState", category: "AppState")
	private var cancellableSet: Set<AnyCancellable> = []
	
	// Public variables
	@Published public var currentTab: Tab = .home
	public var isLowPowerModeEnabled: Bool {
		get { ProcessInfo.processInfo.isLowPowerModeEnabled }
	}
	public var shortcutItemToProcess: UIApplicationShortcutItem?
	public let networkingMonitor: NWPathMonitor = NWPathMonitor()
	
	private init() {
		logger.debug("Initialized")
		self.networkingMonitor.start(queue: .global())
	}
}

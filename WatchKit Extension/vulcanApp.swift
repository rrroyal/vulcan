//
//  vulcanApp.swift
//  WatchKit Extension
//
//  Created by royal on 03/09/2020.
//

import SwiftUI
import Vulcan

@main
struct vulcanApp: App {
	@WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate: ExtensionDelegate
	@StateObject private var vulcanStore: VulcanStore = VulcanStore.shared
	
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
					.navigationTitle(Text("vulcan"))
					.environmentObject(vulcanStore)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

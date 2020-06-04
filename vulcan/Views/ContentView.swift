//
//  ContentView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

enum ScreenPage {
	case home
	case grades
	case schedule
	case tasks
	case messages
	case settings
}

/// Base view, containing TabView with other main views
struct ContentView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	@State public var currentTab: ScreenPage = .home
	@State public var shouldPresentOnboarding: Bool = !UserDefaults.user.launchedBefore
	@State var isNotificationVisible: Bool = false
	
	var body: some View {
		TabView(selection: $currentTab) {
			// Home
			HomeView()
				.environmentObject(self.VulcanAPI)
				.environmentObject(self.Settings)
				.tag(ScreenPage.home)
				.tabItem {
					Image(systemName: "house.fill")
					Text("Home")
				}
			
			// Grades
			GradesView()
				.environmentObject(self.VulcanAPI)
				.environmentObject(self.Settings)
				.tag(ScreenPage.grades)
				.tabItem {
					Image(systemName: "rosette")
					Text("Grades")
				}
			
			// Schedule
			ScheduleView()
				.environmentObject(self.VulcanAPI)
				.environmentObject(self.Settings)
				.tag(ScreenPage.schedule)
				.tabItem {
					Image(systemName: "calendar")
					Text("Schedule")
				}
			
			// Tasks
			TasksView()
				.environmentObject(self.VulcanAPI)
				.environmentObject(self.Settings)
				.tag(ScreenPage.tasks)
				.tabItem {
					Image(systemName: "doc.on.clipboard.fill")
					Text("Tasks")
				}
			
			// Messages
			MessagesView()
				.environmentObject(self.VulcanAPI)
				.environmentObject(self.Settings)
				.tag(ScreenPage.messages)
				.tabItem {
					Image(systemName: "text.bubble.fill")
					Text("Messages")
				}
		}
		// .loadingOverlay((self.VulcanAPI.selectedUser == nil) && UserDefaults.user.isLoggedIn)
		.sheet(isPresented: $shouldPresentOnboarding, onDismiss: {
			self.shouldPresentOnboarding = false
		}, content: {
			OnboardingView(isPresented: self.$shouldPresentOnboarding)
				.environmentObject(self.VulcanAPI)
		})
		.overlay(NotificationOverlay(isPresented: self.$Settings.isNotificationVisible, notificationData: self.$Settings.notificationData, publisher: self.Settings.notificationPublisher))
		.onAppear {
			if (!(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				(UIApplication.shared.delegate as! AppDelegate).sendNotification(NotificationData(autodismisses: true, dismissable: true, style: .normal, icon: "wifi.slash", title: "NO_CONNECTION_TITLE", subtitle: "NO_CONNECTION_SUBTITLE", expandedText: nil))
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(currentTab: .home)
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
    }
}

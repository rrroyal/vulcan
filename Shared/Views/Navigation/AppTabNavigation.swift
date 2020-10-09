//
//  AppTabNavigation.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

import SwiftUI
import Vulcan

struct AppTabNavigation: View {
	@Binding var currentTab: Tab
	@State private var messagesFolder: Vulcan.MessageTag = .received
	
	var body: some View {
		TabView(selection: $currentTab) {
			// Home
			NavigationView {
				#if os(OSX)
				HomeView()
				#else
				HomeView()
					.navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
						Image(systemName: "gear")
							.navigationBarButton(edge: .trailing)
					})
				#endif
			}
			.tabItem {
				Label("Home", systemImage: "house.fill")
					.accessibility(label: Text("Home"))
			}
			.tag(Tab.home)
			.navigationViewStyle(StackNavigationViewStyle())
			.userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").todayActivity") { activity in
				activity.title = NSLocalizedString("Today", comment: "")
				activity.isEligibleForPrediction = true
				activity.isEligibleForSearch = true
				activity.keywords = [NSLocalizedString("Today", comment: ""), "vulcan"]
			}
			
			// Grades
			NavigationView {
				GradesView()
			}
			.tabItem {
				Label("Grades", systemImage: "rosette")
					.accessibility(label: Text("Grades"))
			}
			.tag(Tab.grades)
			.navigationViewStyle(DoubleColumnNavigationViewStyle())
			.userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").gradesActivity", isActive: currentTab == .grades) { activity in
				activity.title = NSLocalizedString("Grades", comment: "")
				activity.isEligibleForPrediction = true
				activity.isEligibleForSearch = true
				activity.keywords = [NSLocalizedString("Grades", comment: ""), "vulcan"]
			}
			
			// Schedule
			NavigationView {
				ScheduleView()
			}
			.tabItem {
				Label("Schedule", systemImage: "calendar")
					.accessibility(label: Text("Schedule"))
			}
			.tag(Tab.schedule)
			.navigationViewStyle(StackNavigationViewStyle())
			.userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").scheduleActivity", isActive: currentTab == .schedule) { activity in
				activity.title = NSLocalizedString("Schedule", comment: "")
				activity.isEligibleForPrediction = true
				activity.isEligibleForSearch = true
				activity.keywords = [
					NSLocalizedString("Schedule", comment: ""),
					NSLocalizedString("Lessons", comment: ""),
					"vulcan"
				]
			}
			
			// Tasks
			NavigationView {
				TasksView()
			}
			.tabItem {
				Label("Tasks", systemImage: "doc.on.clipboard.fill")
					.accessibility(label: Text("Tasks"))
			}
			.tag(Tab.tasks)
			.navigationViewStyle(StackNavigationViewStyle())
			.userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").tasksActivity", isActive: currentTab == .tasks) { activity in
				activity.title = NSLocalizedString("Tasks", comment: "")
				activity.isEligibleForPrediction = true
				activity.isEligibleForSearch = true
				activity.keywords = [NSLocalizedString("Tasks", comment: ""), "vulcan"]
			}
			
			// Messages
			NavigationView {
				MessagesView(tag: $messagesFolder)
			}
			.tabItem {
				Label("Messages", systemImage: "envelope.fill")
					.accessibility(label: Text("Messages"))
			}
			.tag(Tab.messages)
			.navigationViewStyle(DoubleColumnNavigationViewStyle())
			.userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").messagesActivity", isActive: currentTab == .messages) { activity in
				activity.title = NSLocalizedString("Messages", comment: "")
				activity.isEligibleForPrediction = true
				activity.isEligibleForSearch = true
				activity.keywords = [NSLocalizedString("Messages", comment: ""), "vulcan"]
			}
		}
	}
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
		AppTabNavigation(currentTab: .constant(.home))
    }
}

//
//  AppTabNavigation.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

import SwiftUI
import Vulcan

struct AppTabNavigation: View {
	@ObservedObject var appState: AppState
	
	@State private var messagesFolder: Vulcan.MessageTag = .received
	
	var body: some View {
		TabView(selection: $appState.currentTab[0]) {
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
			
			// Grades
			NavigationView {
				GradesView()
				
				Text("Nothing selected")
					.opacity(0.3)
			}
			.tabItem {
				Label("Grades", systemImage: "rosette")
					.accessibility(label: Text("Grades"))
			}
			.tag(Tab.grades)
			.navigationViewStyle(DoubleColumnNavigationViewStyle())
			
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
			
			// Messages
			NavigationView {
				MessagesView(tag: $messagesFolder)
				
				Text("Nothing selected")
					.opacity(0.3)
			}
			.tabItem {
				Label("Messages", systemImage: "envelope.fill")
					.accessibility(label: Text("Messages"))
			}
			.tag(Tab.messages)
			.navigationViewStyle(DoubleColumnNavigationViewStyle())
		}
	}
}

struct AppTabNavigation_Previews: PreviewProvider {
    static var previews: some View {
		AppTabNavigation(appState: AppState.shared)
    }
}

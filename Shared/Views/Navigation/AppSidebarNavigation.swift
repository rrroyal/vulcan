//
//  AppSidebarNavigation.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

import SwiftUI
import Vulcan

struct AppSidebarNavigation: View {
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	@State private var currentTab: Set<Tab> = [.home]
	
	private var sidebar: some View {
		List(selection: $currentTab) {
			// Home
			NavigationLink(destination: HomeView()) {
				Label("Home", systemImage: "house")
			}
			.accessibility(label: Text("Home"))
			.tag(Tab.home)
			
			// Grades
			NavigationLink(destination: GradesView()) {
				Label("Grades", systemImage: "rosette")
			}
			.accessibility(label: Text("Grades"))
			.tag(Tab.grades)

			// Schedule
			NavigationLink(destination: ScheduleView()) {
				Label("Schedule", systemImage: "calendar")
			}
			.accessibility(label: Text("Schedule"))
			.tag(Tab.schedule)
			
			// Tasks
			NavigationLink(destination: TasksView()) {
				Label("Tasks", systemImage: "doc.on.clipboard")
			}
			.accessibility(label: Text("Tasks"))
			.tag(Tab.tasks)
			
			// Messages
			Section(header: Text("Messages").textCase(.none)) {
				// Received
				NavigationLink(destination: MessagesView(tag: .constant(.received))) {
					Label("Received", systemImage: "envelope")
				}
				.accessibility(label: Text("Received messages"))
				.tag(Tab.messages)
				
				// Sent
				NavigationLink(destination: MessagesView(tag: .constant(.sent))) {
					Label("Sent", systemImage: "paperplane")
				}
				.accessibility(label: Text("Sent messages"))
				.tag(Tab.messages)
				
				// Deleted
				NavigationLink(destination: MessagesView(tag: .constant(.deleted))) {
					Label("Deleted", systemImage: "trash")
				}
				.accessibility(label: Text("Deleted messages"))
				.tag(Tab.messages)
			}
			
			Divider()
			
			// Settings
			NavigationLink(destination: SettingsView()) {
				Label("Settings", systemImage: "gear")
			}
			.accessibility(label: Text("Settings"))
			.tag(Tab.settings)
		}
		.listStyle(SidebarListStyle())
		.navigationTitle(Text("vulcan"))
	}
	
	var body: some View {
		NavigationView {
			sidebar
			
			HomeView()
				.tag(Tab.home)
			
			#if os(macOS)
			Text("Nothing selected")
				.opacity(0.5)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.toolbar { Spacer() }
			#else
			Text("Nothing selected")
				.opacity(0.5)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			#endif
		}
	}
}

struct AppSidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
		AppSidebarNavigation()
    }
}

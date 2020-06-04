//
//  ContentView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 29/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
    var body: some View {
		// let messagesEmoji: String = self.VulcanStore.messages.received.contains(where: { !$0.hasBeenRead }) ? "📫" : "📪"
		
		return Group {
			if (!UserDefaults.user.isLoggedIn) {
				Text("Not logged in")
					.opacity(0.3)
			} else {
				List {
					// Schedule
					NavigationLink(destination: ScheduleView().environmentObject(self.VulcanStore)) {
						VStack(alignment: .leading) {
							Text("🗓")
								.font(.body)
								.padding(.bottom)
							Text("Schedule")
								.font(.headline)
						}
					}
					.frame(height: 80)
					
					// Grades
					NavigationLink(destination: GradesView().environmentObject(self.VulcanStore)) {
						VStack(alignment: .leading) {
							Text("🏅")
								.font(.body)
								.padding(.bottom)
							Text("Grades")
								.font(.headline)
						}
					}
					.frame(height: 80)
					
					// EOT Grades
					NavigationLink(destination: EOTGradesView().environmentObject(self.VulcanStore)) {
						VStack(alignment: .leading) {
							Text("🎉")
								.font(.body)
								.padding(.bottom)
							Text("Final grades")
								.font(.headline)
						}
					}
					.frame(height: 80)
					
					// Tasks
					NavigationLink(destination: TasksView().environmentObject(self.VulcanStore)) {
						VStack(alignment: .leading) {
							Text("📚")
								.font(.body)
								.padding(.bottom)
							Text("Tasks")
								.font(.headline)
						}
					}
					.frame(height: 80)
					
					#if DEBUG
					// Debug
					NavigationLink(destination: DebugView().environmentObject(self.VulcanStore)) {
						VStack(alignment: .leading) {
							Text("🤫")
								.font(.body)
								.padding(.bottom)
							Text("Debug")
								.font(.headline)
						}
					}
					.frame(height: 80)
					#endif
				}
				.listStyle(CarouselListStyle())
				.navigationBarTitle(Text("vulcan"))
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ContentView.swift
//  WatchKit Extension
//
//  Created by royal on 03/09/2020.
//

import SwiftUI
import Vulcan

struct ContentView: View {
	@ObservedObject var vulcanStore: VulcanStore = VulcanStore.shared
		
	var messagesEmoji: String {
		(vulcanStore.receivedMessages).contains(where: { !$0.hasBeenRead }) ? "📫" : "📪"
	}
	
	var loggedInView: some View {
		List {
			NavigationLink(destination: ScheduleView()) {
				HomeCardCell(title: "Schedule", emoji: "📆")
			}
			NavigationLink(destination: GradesView()) {
				HomeCardCell(title: "Grades", emoji: "🏅")
			}
			NavigationLink(destination: FinalGradesView()) {
				HomeCardCell(title: "Final Grades", emoji: "🎉")
			}
			NavigationLink(destination: TasksView()) {
				HomeCardCell(title: "Tasks", emoji: "📚")
			}
			NavigationLink(destination: MessagesView()) {
				HomeCardCell(title: "Messages", emoji: messagesEmoji)
			}
			
			#if DEBUG
			NavigationLink(destination: DebugView()) {
				HomeCardCell(title: "Debug", emoji: "🤫")
			}
			#endif
		}
		.listStyle(CarouselListStyle())
	}
	
    var body: some View {
		if vulcanStore.currentUser != nil {
			loggedInView
		} else {
			VStack {
				Text("Not logged in")
					.padding()
				
				Button("Refresh") {
					WKInterfaceDevice.current().play(.start)
					try? WatchSessionManager.shared.sendData(["type": "Request", "requestedData": "InitData"])
				}
			}
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

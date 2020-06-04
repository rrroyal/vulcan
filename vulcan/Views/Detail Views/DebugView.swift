//
//  DebugView.swift
//  vulcan
//
//  Created by royal on 02/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import BackgroundTasks

/// Debug view
struct DebugView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	@State var pendingTaskRequests: [BGTaskRequest] = []
	
	var body: some View {
		List {
			// VulcanAPI
			Section(header: Text("VulcanAPI")) {
				// Reset EOT grades
				Button(action: {
					print("[!] (Debug) Resetting EOT grades!")
					self.VulcanAPI.endOfTermGrades = Vulcan.TermGrades(anticipated: [], final: [])
					self.VulcanAPI.dataState.eotGrades.fetched = false
					self.VulcanAPI.dataState.eotGrades.lastFetched = nil
					self.VulcanAPI.dataState.eotGrades.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset EOT grades")
						.foregroundColor(.red)
				}
				
				// Reset notes
				Button(action: {
					print("[!] (Debug) Resetting notes!")
					self.VulcanAPI.notes.removeAll()
					self.VulcanAPI.dataState.notes.fetched = false
					self.VulcanAPI.dataState.notes.lastFetched = nil
					self.VulcanAPI.dataState.notes.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset notes")
						.foregroundColor(.red)
				}
				
				// Reset grades
				Button(action: {
					print("[!] (Debug) Resetting grades!")
					self.VulcanAPI.grades.removeAll()
					self.VulcanAPI.dataState.grades.fetched = false
					self.VulcanAPI.dataState.grades.lastFetched = nil
					self.VulcanAPI.dataState.grades.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset grades")
						.foregroundColor(.red)
				}
				
				// Reset schedule
				Button(action: {
					print("[!] (Debug) Resetting schedule!")
					self.VulcanAPI.schedule.removeAll()
					self.VulcanAPI.dataState.schedule.fetched = false
					self.VulcanAPI.dataState.schedule.lastFetched = nil
					self.VulcanAPI.dataState.schedule.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset schedule")
						.foregroundColor(.red)
				}
				
				// Reset tasks
				Button(action: {
					print("[!] (Debug) Resetting tasks!")
					self.VulcanAPI.tasks.exams.removeAll()
					self.VulcanAPI.tasks.homework.removeAll()
					self.VulcanAPI.dataState.tasks.fetched = false
					self.VulcanAPI.dataState.tasks.lastFetched = nil
					self.VulcanAPI.dataState.tasks.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset tasks")
						.foregroundColor(.red)
				}
				
				// Reset messages
				Button(action: {
					print("[!] (Debug) Resetting messages!")
					self.VulcanAPI.messages.deleted.removeAll()
					self.VulcanAPI.messages.received.removeAll()
					self.VulcanAPI.messages.sent.removeAll()
					self.VulcanAPI.dataState.messages.fetched = false
					self.VulcanAPI.dataState.messages.lastFetched = nil
					self.VulcanAPI.dataState.messages.loading = false
					generateHaptic(.light)
				}) {
					Text("Reset messages")
						.foregroundColor(.red)
				}
			}
			
			// Core Data
			Section(header: Text("Core Data")) {
				VStack(alignment: .leading) {
					Text("Database URL")
						.font(.headline)
					Text("\(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.object(forInfoDictionaryKey: "GroupIdentifier") as? String ?? "")!.appendingPathComponent("vulcan.sqlite"))")
						.font(.body)
						.lineLimit(nil)
				}
			}
			
			// Background tasks
			Section(header: Text("Background tasks")) {
				// Schedule new
				Button(action: {
					(UIApplication.shared.delegate as! AppDelegate).scheduleAppRefresh()
					BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { items in
						self.pendingTaskRequests = items
					})
					generateHaptic(.light)
				}) {
					Text("Register refresh background task")
				}
				
				// Cancel all
				Button(action: {
					BGTaskScheduler.shared.cancelAllTaskRequests()
					BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { items in
						self.pendingTaskRequests = items
					})
					generateHaptic(.light)
				}) {
					Text("Cancel all tasks")
				}
				
				// Scheduled events
				ForEach(self.pendingTaskRequests, id: \.identifier) { item in
					Text(String(describing: item))
				}
			}
		}
		.environment(\.horizontalSizeClass, .regular)
		.listStyle(GroupedListStyle())
		.navigationBarTitle(Text("Debug"))
		.onAppear {
			BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { items in
				self.pendingTaskRequests = items
			})
		}
	}
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

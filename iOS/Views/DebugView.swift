//
//  DebugView.swift
//  vulcan
//
//  Created by royal on 02/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import WidgetKit
import BackgroundTasks
import os
import Vulcan

/// Debug view
struct DebugView: View {
	@ObservedObject var vulcan: Vulcan = Vulcan.shared
	@State private var pendingTaskRequests: [BGTaskRequest] = []
	private let logger: Logger = Logger(subsystem: "Debug", category: "Debug")
	
	var body: some View {
		List {
			// VulcanAPI
			Section(header: Text("VulcanAPI").textCase(.none)) {
				// Reset dictionary
				Button(action: {
					logger.debug("Resetting dictionary!")
					vulcan.getDictionary(force: true)
					generateHaptic(.light)
				}) {
					Text("Reset dictionary")
						.foregroundColor(.red)
				}
			}
			.padding(.vertical, 10)
			
			// Core Data
			Section(header: Text("Core Data").textCase(.none)) {
				VStack(alignment: .leading) {
					Text("Database URL")
						.font(.headline)
					Text(CoreDataModel.shared.persistentContainer.persistentStoreDescriptions.first?.url?.absoluteString ?? "none")
						.font(.body)
						.lineLimit(nil)
				}
			}
			.padding(.vertical, 10)

			// Background tasks
			Section(header: Text("Background tasks").textCase(.none)) {
				// Schedule new
				Button(action: {
					logger.debug("Scheduling new BGRefresh task.")
					(UIApplication.shared.delegate as? AppDelegate)?.scheduleBackgroundRefresh()
					BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { (items) in
						pendingTaskRequests = items
					})
					generateHaptic(.light)
				}) {
					Text("Register refresh background task")
				}
				
				// Cancel all
				Button(action: {
					logger.debug("Cancelling all BGRefresh tasks.")
					BGTaskScheduler.shared.cancelAllTaskRequests()
					BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { (items) in
						pendingTaskRequests = items
					})
					generateHaptic(.light)
				}) {
					Text("Cancel all tasks")
				}
				
				// Scheduled events
				ForEach(pendingTaskRequests, id: \.identifier) { (item) in
					Text(String(describing: item))
				}
			}
			.padding(.vertical, 10)
			
			// WidgetKit
			Section(header: Text("WidgetKit").textCase(.none)) {
				// Refresh
				Button(action: {
					logger.debug("Reloading widget timelines.")
					WidgetCenter.shared.reloadAllTimelines()
					generateHaptic(.light)
				}) {
					Text("Reload all timelines")
				}
			}
			.padding(.vertical, 10)
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Debug"))
		.onAppear {
			BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { (items) in
				pendingTaskRequests = items
			})
		}
	}
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

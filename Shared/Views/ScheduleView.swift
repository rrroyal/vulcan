//
//  ScheduleView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

/// View containing schedule for the current week.
struct ScheduleView: View {
	@EnvironmentObject var appState: AppState
	@EnvironmentObject var vulcan: Vulcan
	
	@AppStorage(UserDefaults.AppKeys.userGroup.rawValue, store: .group) public var userGroup: Int = 1
	@AppStorage(UserDefaults.AppKeys.filterSchedule.rawValue, store: .group) private var filterSchedule: Bool = false
	
	@State private var date: Date = Date()
		
	/// Loads the data for the current week.
	private func fetch(timeIntervalSince1970: Double? = nil) {
		if (vulcan.dataState.schedule.loading) {
			return
		}
		
		let previousDate: Date = self.date
		guard let startDate: Date = date.startOfWeek, let endDate: Date = date.endOfWeek else {
			return
		}
		
		vulcan.getSchedule(isPersistent: (date.startOfWeek ?? date.startOfDay) == (Date().startOfWeek ?? Date().startOfDay), from: startDate, to: endDate) { error in
			if let error = error {
				generateHaptic(.error)
				self.date = previousDate
				AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
			}
		}
	}
	
	/// Date picker
	private var datePicker: some View {
		DatePicker("Date", selection: $date, displayedComponents: .date)
			.datePickerStyle(CompactDatePickerStyle())
			.labelsHidden()
			.onChange(of: date.timeIntervalSince1970, perform: fetch)
	}
	
	/// View displayed when there are any lessons.
	private var lessonsList: some View {
		ForEach(vulcan.schedule) { day in
			if (filterSchedule ? Calendar.autoupdatingCurrent.isDate(day.date, inSameDayAs: date) : true) {
				Section(header: Text(day.date.formattedDateString(dateStyle: .full, context: .beginningOfSentence)).textCase(.none)) {
					ForEach(day.events.filter { $0.group ?? userGroup == userGroup }) { event in
						ScheduleEventCell(event: event, group: userGroup)
					}
				}
			}
		}
	}
	
	var body: some View {
		List {
			// Schedule
			if (filterSchedule ? vulcan.schedule.filter({ Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: date) }).count == 0 : vulcan.schedule.count == 0) {
				Text(filterSchedule ? "No lessons for this day 😊" : "No lessons for this week 😊")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			} else {
				lessonsList
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationViewStyle(StackNavigationViewStyle())
		.navigationTitle(Text("Schedule"))
		.toolbar {
			// Date picker
			ToolbarItem(placement: .cancellationAction) {
				datePicker
			}
			
			// Refresh button
			ToolbarItem(placement: .primaryAction) {
				RefreshButton(loading: vulcan.dataState.schedule.loading, iconName: "arrow.clockwise", edge: .trailing) {
					generateHaptic(.light)
					fetch()
				}
			}
		}
		.onAppear {
			if (!AppState.networking.monitor.currentPath.isExpensive && vulcan.currentUser != nil && !vulcan.dataState.schedule.fetched || (vulcan.dataState.schedule.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date())) {
				fetch()
			}
		}
	}
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}

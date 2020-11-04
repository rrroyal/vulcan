//
//  ScheduleView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications
import CoreSpotlight
import CoreServices

/// View containing schedule for the current week.
struct ScheduleView: View {
	@EnvironmentObject var vulcan: Vulcan
	
	public static let activityIdentifier: String = "\(Bundle.main.bundleIdentifier ?? "vulcan").ScheduleActivity"
	public static let nextScheduleEventActivityIdentifier: String = "\(Bundle.main.bundleIdentifier ?? "vulcan").NextScheduleEventActivity"
	
	@AppStorage(UserDefaults.AppKeys.showAllScheduleEvents.rawValue, store: .group) public var showAllScheduleEvents: Bool = false
	@AppStorage(UserDefaults.AppKeys.filterSchedule.rawValue, store: .group) private var filterSchedule: Bool = false
	
	@State private var date: Date = Date()
		
	/// Loads the data for the current week.
	private func fetch(timeIntervalSince1970: Double? = nil) {
		if vulcan.dataState.schedule.loading {
			return
		}
		
		let previousDate: Date = self.date
		guard let startDate: Date = date.startOfWeek, let endDate: Date = date.endOfWeek else {
			return
		}
		
		vulcan.getSchedule(isPersistent: startDate >= Date().startOfWeek ?? Date(), from: startDate, to: endDate) { error in
			if let error = error {
				generateHaptic(.error)
				self.date = previousDate
				AppNotifications.shared.notification = .init(error: error.localizedDescription)
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
					ForEach(day.events.filter({ showAllScheduleEvents ? true : $0.isUserSchedule })) { event in
						ScheduleEventCell(event: event, showAllScheduleEvents: showAllScheduleEvents)
					}
				}
			}
		}
	}
	
	var body: some View {
		List {
			// Schedule
			if (filterSchedule ? vulcan.schedule.filter({ Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: date) }).isEmpty : vulcan.schedule.isEmpty) {
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
		/* .userActivity("\(Bundle.main.bundleIdentifier ?? "vulcan").nextScheduleEventActivity") { activity in
			guard let event = vulcan.schedule.flatMap(\.events).first(where: { $0.isUserSchedule && $0.dateStarts ?? $0.date >= Date() }),
				  let dateStarts = event.dateStarts,
				  let dateEnds = event.dateEnds else {
				return
			}
			
			activity.title = "Next up".localized
			activity.isEligibleForPrediction = true
			activity.isEligibleForSearch = true
			activity.keywords = [
				"Schedule".localized,
				"Next lesson".localized
			]
			activity.expirationDate = dateEnds
			activity.persistentIdentifier = event.id
			
			let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			attributes.title = event.subjectName
			attributes.startDate = dateStarts
			attributes.endDate = dateEnds
			attributes.contentDescription = "\(event.employeeFullName ?? "Unknown employee".localized) • \(event.room)"
			attributes.identifier = event.id
			attributes.relatedUniqueIdentifier = event.id
			activity.contentAttributeSet = attributes
		} */
		.userActivity(Self.activityIdentifier) { activity in
			activity.isEligibleForSearch = true
			activity.isEligibleForPrediction = true
			activity.isEligibleForPublicIndexing = true
			activity.isEligibleForHandoff = false
			activity.title = "Schedule".localized
			activity.keywords = [
				"Schedule".localized,
				"Lessons".localized,
				"Next up".localized
			]
			activity.persistentIdentifier = "ScheduleActivity"
			
			let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			attributes.contentDescription = "See your schedule".localized
			
			activity.contentAttributeSet = attributes
		}
		.onAppear {
			if AppState.shared.networkingMonitor.currentPath.isExpensive || AppState.shared.isLowPowerModeEnabled || vulcan.currentUser == nil {
				return
			}
			
			let nextFetch: Date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: vulcan.dataState.schedule.lastFetched ?? Date(timeIntervalSince1970: 0)) ?? Date()
			if nextFetch <= Date() {
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

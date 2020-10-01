//
//  Vulcan+.swift
//  
//
//  Created by royal on 03/09/2020.
//

import Foundation

#if os(iOS) || os(macOS)
import EventKit

public extension VulcanTask {
	func addToReminders(type: Bool? = nil) {
		let eventStore: EKEventStore = EKEventStore()
		eventStore.requestAccess(to: .reminder) {
			granted, error in
			if (granted && error == nil) {
				let tag: String
				
				if let type = type {
					tag = NSLocalizedString(type ? "EXAM_BIG" : "EXAM_SMALL", comment: "")
				} else {
					switch (self.tag) {
						case .exam:		tag = NSLocalizedString("TAG_EXAM", comment: "")
						case .homework:	tag = NSLocalizedString("TAG_HOMEWORK", comment: "")
					}
				}
				
				let event: EKReminder = EKReminder(eventStore: eventStore)
				if let subjectName = self.subject?.name {
					event.title = "\(tag): \(subjectName)"
				} else {
					event.title = "\(tag): \(self.subjectID)"
				}
				event.notes = self.entry
				event.calendar = eventStore.defaultCalendarForNewReminders()
				
				let date: Date = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 9, to: self.date) ?? self.date
				let alarm = EKAlarm(absoluteDate: date)
				event.addAlarm(alarm)
				
				let predicate = eventStore.predicateForReminders(in: [event.calendar])
				eventStore.fetchReminders(matching: predicate) { events in
					let eventAlreadyExists: Bool = events?.contains(where: { $0.title == event.title && $0.notes == event.notes && $0.alarms == event.alarms }) ?? false
					
					if !eventAlreadyExists {
						try? eventStore.save(event, commit: true)
					}
				}
			}
		}
	}
	
	func addToCalendar(type: Bool? = nil) {
		let eventStore: EKEventStore = EKEventStore()
		eventStore.requestAccess(to: .event) {
			granted, error in
			if (granted && error == nil) {
				let tag: String
				
				if let type = type {
					tag = NSLocalizedString(type ? "EXAM_BIG" : "EXAM_SMALL", comment: "")
				} else {
					switch (self.tag) {
						case .exam:		tag = NSLocalizedString("TAG_EXAM", comment: "")
						case .homework:	tag = NSLocalizedString("TAG_HOMEWORK", comment: "")
					}
				}
				
				let event: EKEvent = EKEvent(eventStore: eventStore)
				if let subjectName = self.subject?.name {
					event.title = "\(tag): \(subjectName)"
				} else {
					event.title = "\(tag): \(self.subjectID)"
				}
				event.isAllDay = true
				event.startDate = self.date
				event.endDate = self.date
				event.notes = self.entry
				event.calendar = eventStore.defaultCalendarForNewEvents
				
				let predicate = eventStore.predicateForEvents(withStart: self.date.startOfDay, end: self.date.endOfDay, calendars: nil)
				let existingEvents = eventStore.events(matching: predicate)
				let eventAlreadyExists = existingEvents.contains(where: { $0.title == event.title && $0.notes == event.notes && $0.startDate == event.startDate && $0.endDate == event.endDate })
				
				if !eventAlreadyExists {
					try? eventStore.save(event, span: .thisEvent)
				}
			}
		}
	}
}
#endif

//
//  Array.swift
//  Vulcan
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import Foundation

public extension Sequence where Iterator.Element: Hashable {
	var uniques: [Iterator.Element] {
		var seen: [Iterator.Element: Bool] = [:]
		return self.filter { seen.updateValue(true, forKey: $0) == nil }
	}
}

public extension Array where Element == Vulcan.ScheduleEvent {
	/// Events for the selected day.
	/// - Parameter day: Filter by this date
	/// - Returns: Array of `Vulcan.ScheduleEvent`
	func eventsForDay(_ day: Date) -> [Vulcan.ScheduleEvent] {
		return self.filter { Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: day) }
	}
	
	func timeline() -> [(Date, Vulcan.ScheduleEvent)] {
		return self
			.enumerated()
			.map { index, event in
				var date: Date {
					if index - 1 < 0 {
						return Calendar.autoupdatingCurrent.startOfDay(for: (event.dateStarts ?? event.date))
					}
					
					if let previousEventDateStarts: Date = self[index - 1].dateStarts,
					   let previousEventDateEnds: Date = self[index - 1].dateEnds {
						return Date(timeIntervalSinceReferenceDate: (previousEventDateStarts.timeIntervalSinceReferenceDate + previousEventDateEnds.timeIntervalSinceReferenceDate) / 2)
					} else {
						return event.dateStarts ?? Calendar.autoupdatingCurrent.startOfDay(for: event.date)
					}
				}
				
				return (date, event)
			}
	}
}

public extension Array where Element == Vulcan.EndOfTermGrade {
	var expected: [Vulcan.EndOfTermGrade] {
		return self.filter { $0.type == .expected }
	}
	
	var final: [Vulcan.EndOfTermGrade] {
		return self.filter { $0.type == .final }
	}
}

public extension Array where Element == StoredScheduleEvent {
	var grouped: [Date: [StoredScheduleEvent]] {
		return Dictionary(grouping: self, by: { Date(timeIntervalSince1970: TimeInterval($0.dateEpoch)) })
	}
}

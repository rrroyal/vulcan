//
//  ScheduleEntry.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import WidgetKit
import Vulcan

struct ScheduleEntry: TimelineEntry {
	let date: Date
	let event: Vulcan.ScheduleEvent?
	
	var relevance: TimelineEntryRelevance? {
		guard let event: Vulcan.ScheduleEvent = self.event else {
			return TimelineEntryRelevance(score: 0.1)
		}
				
		if let dateStarts = event.dateStarts,
		   let dateEnds = event.dateEnds {
			return TimelineEntryRelevance(score: 1, duration: dateStarts.timeIntervalSince1970 - dateEnds.timeIntervalSince1970)
		} else {
			return TimelineEntryRelevance(score: 0.5)
		}
	}
}

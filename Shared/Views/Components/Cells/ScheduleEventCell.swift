//
//  ScheduleEventCell.swift
//  vulcan
//
//  Created by royal on 07/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan

struct ScheduleEventCell: View {
	let event: Vulcan.ScheduleEvent
	let showAllScheduleEvents: Bool
		
    var body: some View {
		VStack(alignment: .center, spacing: 4) {
			// First row: Subject name and room
			HStack(alignment: .center, spacing: 0) {
				// Subject name
				Text(event.subject?.name ?? event.subjectName)
					.font(.headline)
					.strikethrough(event.labelStrikethrough)
					.underline(event.labelBold)
					.allowsTightening(true)
					.minimumScaleFactor(0.3)
					.lineLimit(2)
				
				Spacer()
				
				// Room
				Group {
					if let division = event.divisionShort,
					   showAllScheduleEvents {
						Text("\(event.room) (\(division))")
					} else {
						Text(event.room)
					}
				}
				.font(.body)
				.allowsTightening(true)
				.minimumScaleFactor(0.75)
				.lineLimit(1)
			}
			
			// Second row: Time and teacher
			HStack(alignment: .center, spacing: 0) {
				// Time, teacher
				Text("\(event.dateStarts?.localizedTime ?? "") - \(event.dateEnds?.localizedTime ?? "") • \(event.employee?.name ?? "Unknown") \(event.employee?.surname ?? "employee")")
					.font(.callout)
					.foregroundColor((event.dateStarts ?? Date(timeIntervalSince1970: 0) < Date() && event.dateEnds ?? Date(timeIntervalSince1970: 0) > Date()) ? Color.accentColor : Color.secondary)
					.allowsTightening(true)
					.minimumScaleFactor(0.75)
					.lineLimit(1)
				
				Spacer()
			}
			
			// Third row: Note
			if let note = event.note, !note.isReallyEmpty {
				HStack(alignment: .center, spacing: 0) {
					Text(note)
						.font(.callout)
						.foregroundColor((event.dateStarts ?? Date(timeIntervalSince1970: 0) < Date() && event.dateEnds ?? Date(timeIntervalSince1970: 0) > Date()) ? Color.accentColor : Color.secondary)
						.allowsTightening(true)
						.minimumScaleFactor(0.75)
						.lineLimit(3)
					
					Spacer()
				}
			}
		}
		.padding(.vertical, 10)
		.foregroundColor((event.dateStarts ?? Date(timeIntervalSince1970: 0) < Date() && event.dateEnds ?? Date(timeIntervalSince1970: 0) > Date()) ? Color.accentColor : Color.primary)
		.opacity((event.dateEnds ?? event.date < Date()) ? 0.5 : 1)
		.id(event.id)
    }
}

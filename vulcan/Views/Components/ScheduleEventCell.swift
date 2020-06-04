//
//  ScheduleEventCell.swift
//  vulcan
//
//  Created by royal on 07/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ScheduleEventCell: View {
	var event: Vulcan.Event
	
    var body: some View {
		VStack(alignment: .center) {
			// First row: Subject name and room
			HStack(alignment: .center, spacing: 0) {
				// Subject name
				Text(event.group != nil && UserDefaults.user.userGroup == 0 ? "\(event.subject.name) (\(event.group ?? "1/2, 2/2"))" : event.subject.name)
					.font(.headline)
					.strikethrough(event.strikethrough)
					.underline(event.bold)
					.allowsTightening(true)
					.minimumScaleFactor(0.3)
					.lineLimit(2)
				
				Spacer()
				
				// Room
				Text(event.room.uppercased())
					.font(.body)
					.allowsTightening(true)
					.minimumScaleFactor(0.75)
					.lineLimit(1)
			}
			.padding(.bottom, 2)
			
			// Second row: Time and teacher
			HStack(alignment: .center, spacing: 0) {
				// Time, teacher
				Text("\(event.dateStarts.localizedTime) - \(event.dateEnds.localizedTime) • \(event.teacher.name) \(event.teacher.surname)")
					.font(.callout)
					.foregroundColor(.secondary)
					.allowsTightening(true)
					.minimumScaleFactor(0.75)
					.lineLimit(1)
				
				Spacer()
			}
			
			// Third row: Note
			if (event.note != "") {
				HStack(alignment: .center, spacing: 0) {
					Text(event.note)
						// .font(.system(size: 14, weight: .medium, design: .default))
						.font(.callout)
						.foregroundColor(.secondary)
						.allowsTightening(true)
						.minimumScaleFactor(0.75)
						.lineLimit(3)
					
					Spacer()
				}
			}
		}
		.opacity(event.isCurrent ? 1 : event.hasPassed ? 0.25 : 0.6)
		.padding(.vertical, 5)
    }
}

/* struct ScheduleEventCell_Previews: PreviewProvider {
    static var previews: some View {
		ScheduleEventCell(event: Vulcan.Event(
			time: 0,
			dateStarts: Date(),
			dateEnds: Date(),
			lessonOfTheDay: 1,
			lesson: Vulcan.Lesson(id: 1, number: 1, startTime: 0, endTime: 0),
			subject: Vulcan.Subject(id: 0, name: "Subject Name", code: "SCODE", active: true, position: 1),
			group: "1/2",
			room: "s23",
			teacher: Vulcan.Teacher(id: 0, name: "Name", surname: "Surname", code: "TCODE", active: true, teacher: true, loginID: 0),
			note: "",
			strikethrough: false,
			bold: false,
			userSchedule: true
		))
		.previewLayout(.sizeThatFits)
		.padding(10)
    }
} */

//
//  ScheduleEventCell.swift
//  vulcan Today Extension
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ScheduleEventCell: View {
	@State var event: Vulcan.Event
	
    var body: some View {
		let isToday: Bool = event.dateStarts.startOfDay == Date().startOfDay

		return HStack {
			VStack(alignment: .leading) {
				Text(event.group != nil && UserDefaults.user.userGroup == 0 ? "\(event.subject.name) (\(event.group ?? "1/2, 2/2"))" : event.subject.name)
					.font(.headline)
					.lineLimit(2)
				if (isToday) {
					Text("\(event.dateStarts.formattedString(format: "HH:mm")) - \(event.dateEnds.formattedString(format: "HH:mm"))")
				} else {
					Text("\(event.dateStarts.relativeString.capitalingFirstLetter()), \(event.dateStarts.formattedString(format: "HH:mm")) - \(event.dateEnds.formattedString(format: "HH:mm"))")
				}
			}
			Spacer()
			
			Text(event.room)
				.font(.title)
				.bold()
				// .frame(width: 60)
		}
		.opacity(event.isCurrent ? 0.9 : event.hasPassed ? 0.25 : 0.6)
		.padding(.vertical, 7)
		.frame(minHeight: 50, maxHeight: 50)
    }
}

/* struct ScheduleEventCell_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleEventCell()
    }
} */

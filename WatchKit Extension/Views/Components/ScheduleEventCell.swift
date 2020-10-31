//
//  ScheduleEventCell.swift
//  WatchKit Extension
//
//  Created by royal on 09/09/2020.
//

import SwiftUI
import Vulcan

struct ScheduleEventCell: View {
	let event: Vulcan.ScheduleEvent
	
    var body: some View {
		VStack(alignment: .leading) {
			Text(event.subjectName)
				.font(.headline)
			
			if let dateStarts = event.dateStarts,
			   let dateEnds = event.dateEnds {
				Text("\(event.room) • \(dateStarts.localizedTime) - \(dateEnds.localizedTime)")
			} else {
				Text(event.room)
			}
		}
		.opacity(event.dateEnds ?? event.date < Date() ? 0.5 : 1)
		.frame(height: 100)
		// .listRowPlatterColor(event.isCurrent ?? false ? Color.accentColor : nil)
		.listRowPlatterColor((event.dateStarts ?? Date(timeIntervalSince1970: 0) < Date() && event.dateEnds ?? Date(timeIntervalSince1970: 0) > Date()) ? Color.accentColor : nil)
    }
}

/* struct ScheduleEventCell_Previews: PreviewProvider {
    static var previews: some View {
		ScheduleEventCell(event: <#Vulcan.ScheduleEvent#>, group: <#Int#>)
    }
} */

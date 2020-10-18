//
//  SmallEventCell.swift
//  Widget
//
//  Created by Kacper on 18/10/2020.
//

import SwiftUI
import Vulcan

struct SmallEventCell: View {
	let event: Vulcan.ScheduleEvent
	
    var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			// Time
			if let dateStarts = event.dateStarts,
			   let dateEnds = event.dateEnds {
				Text("\(dateStarts.localizedTime) - \(dateEnds.localizedTime)")
					.font(.footnote)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}
			
			// Subject, room
			HStack {
				Text(event.subjectName)
					.font(.headline)
					.lineLimit(1)
					.allowsTightening(true)
					.truncationMode(.middle)
				
				Spacer()
				
				Text(event.room)
			}
		}
    }
}

/* struct SmallEventCell_Previews: PreviewProvider {
    static var previews: some View {
        SmallEventCell()
    }
} */

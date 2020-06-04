//
//  NextEventCell.swift
//  vulcan Today Extension
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct NextEventCell: View {
	@State var event: Vulcan.Event
	
    var body: some View {
		let isToday: Bool = event.dateStarts.startOfDay == Date().startOfDay
		
		return VStack(alignment: .leading) {
			Text("Next class")
				.font(.headline)
				.opacity(0.2)
			
			HStack {
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
			.opacity(0.9)
		}
		.padding()
    }
}

/* struct NextEventCell_Previews: PreviewProvider {
    static var previews: some View {
        NextEventCell()
    }
} */

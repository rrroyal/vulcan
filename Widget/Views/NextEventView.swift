//
//  NextEventView.swift
//  Widget
//
//  Created by Kacper on 18/10/2020.
//

import SwiftUI
import Vulcan

struct NextEventView: View {
	let event: Vulcan.ScheduleEvent?
	
	@Environment(\.colorScheme) var colorScheme
	
	var foregroundColor: Color {
		colorScheme == .light ? .accentColor : .white
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 3) {
			Text("Next up")
				.font(.subheadline)
				.bold()
				.foregroundColor(foregroundColor)
			
			Spacer()
			
			if let event = event {
				// Time / Room
				Group {
					if let dateStarts = event.dateStarts {
						Text("\(dateStarts.localizedTime) • \(event.room)")
					} else {
						Text(event.room)
					}
				}
				.lineLimit(1)
				.font(.subheadline)
				.foregroundColor(foregroundColor.opacity(0.5))
				
				// Subject
				Text(event.subjectName)
					.font(.headline)
					.foregroundColor(foregroundColor)
					.truncationMode(.tail)
					.lineLimit(2)
			} else {
				Text("Nothing left")
					.font(.headline)
					.foregroundColor(foregroundColor)
					.truncationMode(.tail)
					.lineLimit(2)
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		.padding()
	}
}

struct NextEventView_Previews: PreviewProvider {
    static var previews: some View {
        NextEventView(event: nil)
    }
}

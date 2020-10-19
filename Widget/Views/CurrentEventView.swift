//
//  CurrentEventView.swift
//  Widget
//
//  Created by Kacper on 18/10/2020.
//

import SwiftUI
import Vulcan

struct CurrentEventView: View {
	let event: Vulcan.ScheduleEvent?
	
    var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text("Now")
				.font(.subheadline)
				.bold()
				.foregroundColor(.white)
			
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
				.font(.subheadline)
				.foregroundColor(Color.white.opacity(0.8))
				
				// Subject
				Text(event.subjectName)
					.font(.headline)
					.foregroundColor(.white)
					.truncationMode(.tail)
					.lineLimit(2)
			} else {
				Text("Nothing for now 😊")
					.font(.headline)
					.foregroundColor(.white)
					.truncationMode(.tail)
					.lineLimit(2)
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(LinearGradient(gradient: Gradient(colors: [Color("Background/Top"), Color("Background/Bottom")]), startPoint: .top, endPoint: .bottom))
    }
}

struct CurrentEventView_Previews: PreviewProvider {
    static var previews: some View {
		CurrentEventView(event: nil)
    }
}

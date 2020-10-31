//
//  EventView.swift
//  Widget
//
//  Created by royal on 18/10/2020.
//

import SwiftUI
import Vulcan

struct EventView: View {
	let event: Vulcan.ScheduleEvent?
	
	var body: some View {
		if let event = event {
			VStack(alignment: .leading) {
				// Top line: time and room
				HStack {
					if let dateStarts = event.dateStarts {
						Text(dateStarts.localizedTime)
							.font(.subheadline)
							.bold()
							.foregroundColor(.white)
					}
					
					Spacer()
					
					Text(event.room)
						.font(.subheadline)
						.foregroundColor(.white)
				}
				
				Spacer()
				
				// Middle line: subject name
				Text(event.subjectName)
					.font(.headline)
					.foregroundColor(.white)
					.truncationMode(.tail)
					.minimumScaleFactor(0.75)
					.lineLimit(3)
				
				// Bottom line: employee name
				Group {
					if let employeeName = event.employee?.name,
					   let employeeSurname = event.employee?.surname {
						Text("\(employeeName) \(employeeSurname)")
					} else if let employeeFullName = event.employeeFullName {
						Text(employeeFullName)
					}
				}
				.font(.subheadline)
				.foregroundColor(Color.white.opacity(0.8))
				.minimumScaleFactor(0.75)
				.lineLimit(2)
				
			}
			.padding()
			.background(LinearGradient(gradient: Gradient(colors: [Color("Background/Top"), Color("Background/Bottom")]), startPoint: .top, endPoint: .bottom))
		} else {
			VStack(alignment: .leading) {
				Text("vulcan")
					.font(.subheadline)
					.bold()
					.foregroundColor(.white)
				
				Spacer()
				
				Text("No events for now 😊")
					.font(.headline)
					.foregroundColor(.white)
					.truncationMode(.tail)
					.minimumScaleFactor(0.75)
					.lineLimit(3)
				
				/* Text(Provider.noEventSubtitle)
				.font(.subheadline)
				.foregroundColor(Color.white.opacity(0.8))
				.minimumScaleFactor(0.75)
				.lineLimit(3) */
			}
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
			.padding()
			.background(LinearGradient(gradient: Gradient(colors: [Color("Background/Top"), Color("Background/Bottom")]), startPoint: .top, endPoint: .bottom))
		}
	}
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
		EventView(event: nil)
    }
}

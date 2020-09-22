//
//  MediumScheduleWidgetView.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import SwiftUI

struct MediumScheduleWidgetView: View {
	let entry: Provider.Entry
	
	var body: some View {
		if let event = entry.event {
			VStack(alignment: .leading) {
				// Top line: time and room
				HStack {
					if let dateStarts = event.dateStarts,
					   let dateEnds = event.dateEnds {
						Text("\(dateStarts.localizedTime) - \(dateEnds.localizedTime)")
							.font(.headline)
							.foregroundColor(.white)
					}
					
					Spacer()
					
					Text(event.room)
						.font(.body)
						.foregroundColor(.white)
				}
				
				Spacer()
				
				// Middle line: subject name
				Text(event.subjectName)
					.font(.title3)
					.bold()
					.foregroundColor(.white)
					.minimumScaleFactor(0.75)
				
				// Bottom line: employee name
				Group {
					if let employeeName = event.employee?.name,
					   let employeeSurname = event.employee?.surname {
						Text("\(employeeName) \(employeeSurname)")
					} else if let employeeFullName = event.employeeFullName {
						Text(employeeFullName)
					}
				}
				.font(.body)
				.foregroundColor(Color.white.opacity(0.8))
				.minimumScaleFactor(0.75)
			}
			.padding()
		} else {
			VStack(alignment: .leading) {
				Text("vulcan")
					.font(.headline)
					.foregroundColor(.white)
				
				Spacer()
				
				Text("No events for now 😊")
					.font(.title3)
					.bold()
					.foregroundColor(.white)
					.minimumScaleFactor(0.75)
				
				Text(Provider.noEventSubtitle)
					.font(.body)
					.foregroundColor(Color.white.opacity(0.8))
					.minimumScaleFactor(0.75)
					.lineLimit(3)
			}
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
			.padding()
		}
	}
}

struct MediumScheduleWidgetView_Previews: PreviewProvider {
    static var previews: some View {
		MediumScheduleWidgetView(entry: .init(date: Date(), event: nil))
    }
}

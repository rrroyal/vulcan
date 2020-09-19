//
//  SmallScheduleWidgetView.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import SwiftUI

struct SmallScheduleWidgetView: View {
	let entry: Provider.Entry
	
	var body: some View {
		if let event = entry.event {
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
		}
	}
}

struct SmallScheduleWidgetView_Previews: PreviewProvider {
    static var previews: some View {
		SmallScheduleWidgetView(entry: .init(date: Date(), configuration: .init(), event: nil))
    }
}

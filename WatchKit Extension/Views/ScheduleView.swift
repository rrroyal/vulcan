//
//  ScheduleView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI
import Vulcan

struct ScheduleView: View {
	@EnvironmentObject var vulcanStore: VulcanStore
	
	let date: Date = Date()
	
	var events: [Vulcan.ScheduleEvent]? {
		vulcanStore.schedule
			.first(where: {
				$0.events.contains { $0.dateStarts ?? $0.date >= Date() }
			})?
			.events
			.filter { $0.isUserSchedule }
	}
	
    var body: some View {
		Group {
			if ((events ?? []).count > 0) {
				List {
					ForEach(events ?? []) { event in
						ScheduleEventCell(event: event)
					}
				}
				.listStyle(CarouselListStyle())
			} else {
				Text("Nothing left for now ☺️")
					.multilineTextAlignment(.center)
					.opacity(0.3)
			}
		}
		.navigationTitle(Text("Schedule"))
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}

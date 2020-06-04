//
//  ScheduleView.swift
//  vulcan
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ScheduleView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
    var body: some View {
		let schedule: [Vulcan.Event] = self.VulcanStore.schedule.first(where: { $0.events.contains(where: { $0.actualGroup == nil ? !$0.hasPassed : ($0.actualGroup ?? 0) == UserDefaults.user.userGroup && !$0.hasPassed }) == true })?.events.filter({ $0.actualGroup == nil ? true : ($0.actualGroup ?? 0) == UserDefaults.user.userGroup }) ?? []
		
		return List {
			ForEach(schedule) { event in
				VStack(alignment: .leading) {
					Text(event.subject.name)
						.font(.headline)
					Text("\(event.room) • \(event.dateStarts.formattedString(format: "HH:mm")) - \(event.dateEnds.formattedString(format: "HH:mm"))")
				}
				.padding(.vertical)
				.opacity(event.isCurrent ? 1 : event.hasPassed ? 0.25 : 0.6)
				.frame(height: 100)
			}
		}
		.navigationBarTitle(Text("Schedule"))
		.listStyle(CarouselListStyle())
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}

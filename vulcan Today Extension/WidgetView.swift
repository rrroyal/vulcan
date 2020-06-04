//
//  WidgetView.swift
//  vulcan Today Extension
//
//  Created by royal on 29/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct WidgetView: View {
	
	// :/
	func checkIfCompact(_ size: CGSize) -> Bool {
		let widgetHeights: [CGFloat] = [95.0, 100.0, 105.0, 110.0, 120.0, 130.0, 145.0]
		return widgetHeights.contains(size.height)
	}
	
	// i'm so sorry
    var body: some View {
		let nearestDay: Vulcan.Day? = DataModel.shared.schedule.first(where: { $0.events.first(where: { ($0.actualGroup == nil ? !$0.hasPassed : $0.actualGroup == UserDefaults.user.userGroup && !$0.hasPassed) }) != nil })
		 let nearestNewEvent: Vulcan.Event? = nearestDay?.events.first(where: { !$0.isCurrent && ($0.actualGroup == nil ? !$0.hasPassed : $0.actualGroup == UserDefaults.user.userGroup && !$0.hasPassed) })
		
		return GeometryReader { geometry in
			VStack {
				if (!UserDefaults.user.isLoggedIn) {
					Text("Not logged in")
						.opacity(0.3)
				} else {
					if (nearestDay == nil) {
						Text("Nothing found")
							.opacity(0.3)
					} else {
						if (!self.checkIfCompact(geometry.size)) {
							List {
								ForEach(nearestDay?.events ?? []) { event in
									if (event.group == nil || event.actualGroup == UserDefaults.user.userGroup || UserDefaults.user.userGroup == 0) {
										ScheduleEventCell(event: event)
									}
								}
							}
						} else {
							if (nearestNewEvent == nil) {
								Text("Nothing found")
									.opacity(0.3)
							} else {
								NextEventCell(event: nearestNewEvent!)
							}
						}
					}
				}
			}
		}
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetView()
    }
}

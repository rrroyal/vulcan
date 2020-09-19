//
//  ScheduleWidgetEntryView.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import SwiftUI
import WidgetKit

struct ScheduleWidgetEntryView: View {
	var entry: Provider.Entry
	
	@Environment(\.widgetFamily) private var widgetFamily: WidgetFamily
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
	var body: some View {
		switch (widgetFamily) {
			case .systemSmall:	SmallScheduleWidgetView(entry: entry)
			case .systemMedium:	MediumScheduleWidgetView(entry: entry)
			case .systemLarge:	LargeScheduleWidgetView(entry: entry)
			@unknown default:	SmallScheduleWidgetView(entry: entry)
		}
	}
}

struct ScheduleWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
		ScheduleWidgetEntryView(entry: .init(date: Date(), configuration: .init(), event: nil))
    }
}

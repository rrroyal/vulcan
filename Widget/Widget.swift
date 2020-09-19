//
//  widget.swift
//  widget
//
//  Created by royal on 03/09/2020.
//

import WidgetKit
import SwiftUI

@main
struct VulcanWidget: Widget {
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "ScheduleWidget", intent: GroupIntent.self, provider: Provider()) { entry in
			ScheduleWidgetEntryView(entry: entry)
				.accentColor(Color("AccentColor"))
				.background(LinearGradient(gradient: Gradient(colors: [Color("Background/Top"), Color("Background/Bottom")]), startPoint: .top, endPoint: .bottom))
				.widgetURL(URL(string: "vulcan://schedule"))
        }
        .configurationDisplayName("Schedule")
        .description("Displays your schedule.")
		.supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct VulcanWidget_Previews: PreviewProvider {
    static var previews: some View {
		ScheduleWidgetEntryView(entry: ScheduleEntry(date: Date(), configuration: GroupIntent(), event: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

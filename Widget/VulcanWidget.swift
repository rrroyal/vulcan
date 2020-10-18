//
//  VulcanWidget.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import WidgetKit
import SwiftUI

struct NowWidget: Widget {
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: "NowWidget", provider: NowProvider()) { entry in
			NowEntryView(entry: entry)
				.widgetURL(URL(string: "vulcan://schedule"))
				.accentColor(Color("AccentColor"))
		}
		.configurationDisplayName("Now")
		.description("NOW_DESCRIPTION")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

struct NextUpWidget: Widget {
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: "NextUpWidget", provider: NextUpProvider()) { entry in
			NextUpEntryView(entry: entry)
				.widgetURL(URL(string: "vulcan://schedule"))
				.accentColor(Color("AccentColor"))
		}
		.configurationDisplayName("Next up")
		.description("NEXTUP_DESCRIPTION")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

@main
struct VulcanWidget: WidgetBundle {
    var body: some Widget {
		NowWidget()
		NextUpWidget()
    }
}



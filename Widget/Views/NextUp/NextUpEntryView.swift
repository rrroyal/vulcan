//
//  NextUpEntryView.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import SwiftUI
import WidgetKit

struct NextUpEntryView: View {
	let entry: NextUpProvider.Entry

	@Environment(\.widgetFamily) private var widgetFamily: WidgetFamily
	
	var systemSmallView: some View {
		CurrentEventView(event: entry.currentEvent)
	}
	
	var systemMediumView: some View {
		HStack(spacing: 0) {
			CurrentEventView(event: entry.currentEvent)
				.mask(ContainerRelativeShape())
				.shadow(color: Color.black.opacity(0.2), radius: 10)
			
			NextEventView(event: entry.nextEvents.first)
		}
		.background(Color(UIColor.systemGroupedBackground).opacity(0.5))
	}
	
	var systemLargeView: some View {
		GeometryReader { geometry in
			VStack(spacing: 0) {
				CurrentEventView(event: entry.currentEvent)
					.frame(height: geometry.size.height / 2)
					.mask(ContainerRelativeShape())
					.shadow(color: Color.black.opacity(0.2), radius: 10)
				
				VStack(alignment: .center) {
					ForEach(entry.nextEvents.prefix(3)) { event in
						SmallEventCell(event: event)
							.padding(.vertical, 2)
					}					
				}
				.padding(.horizontal)
				.padding(.vertical)
				.frame(height: geometry.size.height / 2)
			}
			.background(Color(UIColor.systemGroupedBackground).opacity(0.5))
		}
	}
	
	var body: some View {
		switch widgetFamily {
			case .systemSmall:	systemSmallView
			case .systemMedium:	systemMediumView
			case .systemLarge:	systemLargeView
			@unknown default:	systemSmallView
		}
	}
}

struct NextUpEntryView_Previews: PreviewProvider {
    static var previews: some View {
		NextUpEntryView(entry: .init(date: Date(), currentEvent: nil, nextEvents: []))
    }
}

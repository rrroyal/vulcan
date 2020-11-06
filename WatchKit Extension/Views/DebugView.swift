//
//  DebugView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI
import ClockKit

struct DebugView: View {
	private let ud = UserDefaults.group
	
    var body: some View {
		List {
			// UserDefaults
			Section(header: Text("UserDefaults").textCase(.none)) {
				// ColorScheme
				HStack {
					Text("colorScheme")
					Spacer()
					Text(ud.string(forKey: "colorScheme") ?? "Default")
				}
				
				// ColorizeGrades
				HStack {
					Text("colorizeGrades")
					Spacer()
					Text(ud.bool(forKey: "colorizeGrades") ? "true" : "false")
				}
				
				// IsLoggedIn
				HStack {
					Text("isLoggedIn")
					Spacer()
					Text(ud.bool(forKey: "isLoggedIn") ? "true" : "false")
				}
				
				// LastSyncDate
				HStack {
					Text("lastSyncDate")
					Spacer()
					Text(Date(timeIntervalSince1970: TimeInterval(ud.integer(forKey: "lastSyncDate"))), style: .date)
				}
			}
			
			// Complications
			Section(header: Text("Complications").textCase(.none)) {
				Button("Reload complications") {
					for complication in CLKComplicationServer.sharedInstance().activeComplications ?? [] {
						CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
					}
				}
				.padding()
								
				ForEach(CLKComplicationServer.sharedInstance().activeComplications ?? [], id: \.identifier) { complication in
					Text("\(complication.identifier): \(complication.family.rawValue)")
				}
			}
		}
		.listStyle(PlainListStyle())
		.navigationTitle(Text("🤫"))
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

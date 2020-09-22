//
//  GradesView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

/// Grades view, showing subject NavigationLinks to grades.
struct GradesView: View {
	@ObservedObject var vulcan: Vulcan = Vulcan.shared
	@ObservedObject var settings: SettingsModel = SettingsModel.shared
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	@State private var selection: Vulcan.SubjectGrades?
	
	/// Refreshes the data
	private func fetch() {
		var requestsError: Error?
		
		vulcan.getGrades() { error in
			requestsError = error
		}
		
		vulcan.getEndOfTermGrades() { error in
			requestsError = error
		}
		
		if let error = requestsError {
			generateHaptic(.error)
			AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
		}
	}
	
	/// Sidebar ViewBuilder
	@ViewBuilder var body: some View {
		List(selection: $selection) {
			if (vulcan.grades.count > 0) {
				ForEach(vulcan.grades) { (subject) in
					NavigationLink(destination: GradesDetailView(subject: subject), tag: subject, selection: $selection) {
						HStack {
							VStack(alignment: .leading, spacing: 5) {
								Text(subject.subject.name)
									.font(.headline)
								Text("\(subject.employee.name) \(subject.employee.surname)")
									.font(.callout)
									.foregroundColor(.secondary)
							}
							.padding(.trailing)
							
							Spacer()
							
							if subject.hasNewItems {
								Image(systemName: "staroflife.fill")
									.padding(.trailing, 5)
							}
						}
						.padding(.vertical, 10)
					}
					.tag(subject.id)
					.id(subject.id)
				}
			} else {
				Text("No grades")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			}
		}
		.listStyle(InsetGroupedListStyle())
		// .sidebarListStyle(horizontalSizeClass: horizontalSizeClass)
		// .navigationViewStyle(DoubleColumnNavigationViewStyle())
		.navigationTitle("Grades")
		/* .navigationBarItems(trailing: RefreshButton(loading: vulcan.dataState.grades.loading, progressValue: vulcan.dataState.grades.progress, iconName: "arrow.clockwise", edge: .trailing) {
		generateHaptic(.light)
		refresh()
		}) */
		.toolbar {
			// Refresh button
			ToolbarItem(placement: .primaryAction) {
				RefreshButton(loading: vulcan.dataState.grades.loading || vulcan.dataState.eotGrades.loading, iconName: "arrow.clockwise", edge: .trailing) {
					generateHaptic(.light)
					fetch()
				}
			}
		}
		.onAppear {
			if (AppState.networking.monitor.currentPath.isExpensive || vulcan.currentUser == nil) {
				return
			}
			
			if (!vulcan.dataState.grades.fetched || (vulcan.dataState.grades.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date())) {
				fetch()
			}
		}
	}
}

struct GradesView_Previews: PreviewProvider {
    static var previews: some View {
        GradesView()
    }
}

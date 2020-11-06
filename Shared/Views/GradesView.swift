//
//  GradesView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications
import CoreSpotlight
import CoreServices

/// Grades view, showing subject NavigationLinks to grades.
struct GradesView: View {
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	@State private var selection: Vulcan.SubjectGrades?
	
	public static let activityIdentifier: String = "\(Bundle.main.bundleIdentifier ?? "vulcan").GradesActivity"
	
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
			UIDevice.current.generateHaptic(.error)
			AppNotifications.shared.notification = .init(error: error.localizedDescription)
		}
	}
	
	/// Sidebar ViewBuilder
	@ViewBuilder var body: some View {
		List(selection: $selection) {
			if (!vulcan.grades.isEmpty) {
				ForEach(vulcan.grades) { subject in
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
		.navigationTitle("Grades")
		.toolbar {
			// Refresh button
			ToolbarItem(placement: .primaryAction) {
				RefreshButton(loading: vulcan.dataState.grades.loading || vulcan.dataState.eotGrades.loading, iconName: "arrow.clockwise", edge: .trailing) {
					UIDevice.current.generateHaptic(.light)
					fetch()
				}
			}
		}
		.userActivity(Self.activityIdentifier) { activity in
			activity.isEligibleForSearch = true
			activity.isEligibleForPrediction = true
			activity.isEligibleForPublicIndexing = true
			activity.isEligibleForHandoff = false
			activity.title = "Grades".localized
			activity.keywords = ["Grades".localized]
			activity.persistentIdentifier = "GradesActivity"
			
			let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
			attributes.contentDescription = "See your grades".localized
			
			activity.contentAttributeSet = attributes
		}
		.onAppear {
			if AppState.shared.networkingMonitor.currentPath.isExpensive || AppState.shared.isLowPowerModeEnabled || vulcan.currentUser == nil {
				return
			}
			
			let nextFetch: Date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: vulcan.dataState.grades.lastFetched ?? Date(timeIntervalSince1970: 0)) ?? Date()
			if nextFetch <= Date() {
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

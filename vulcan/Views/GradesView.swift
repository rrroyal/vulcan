//
//  GradesView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// Grades view, showing subject NavigationLinks to grades
struct GradesView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	var buttonOrIndicator: some View {
		Group {
			if (self.VulcanAPI.dataState.grades.loading) {
				ActivityIndicator(isAnimating: self.$VulcanAPI.dataState.grades.loading, style: .medium)
			} else {
				Button(action: {
					generateHaptic(.light)
					withAnimation {
						self.VulcanAPI.getGrades() { success, error in
							if (error != nil) {
								generateHaptic(.error)
							}
						}
					}
				}, label: {
					Image(systemName: "arrow.clockwise")
						.navigationBarButton(edge: .trailing)
				})
			}
		}
	}
	
	var body: some View {
		NavigationView {
			List(self.VulcanAPI.grades) { grade in
				NavigationLink(destination: GradesDetailView(subject: grade.subject, grades: grade.grades).environmentObject(self.VulcanAPI)) {
					VStack(alignment: .leading) {
						Text(grade.subject.name)
							.font(.headline)
							.padding(.bottom, 2)
						Text("\(grade.subject.teacher?.name ?? "") \(grade.subject.teacher?.surname ?? "")")
							.font(.callout)
							.foregroundColor(.secondary)
					}
					.padding(.vertical, 5)
				}
			}
			.listStyle(GroupedListStyle())
			.environment(\.horizontalSizeClass, .regular)
			.navigationBarTitle(Text("Grades"))
			.navigationBarItems(trailing: buttonOrIndicator)
			
			Text("Nothing selected")
				.opacity(0.1)
		}
		// .allowsHitTesting(!self.VulcanAPI.dataState.grades.loading)
		// .loadingOverlay(self.VulcanAPI.dataState.grades.loading)
		.onAppear {
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || !(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				return
			}
			
			if (!self.VulcanAPI.dataState.grades.fetched || self.VulcanAPI.dataState.grades.lastFetched ?? Date(timeIntervalSince1970: 0) < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				self.VulcanAPI.getGrades() { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
		}
	}
}

struct GradesView_Previews: PreviewProvider {
	static var previews: some View {
		GradesView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
	}
}

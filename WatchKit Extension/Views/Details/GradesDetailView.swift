//
//  GradesDetailView.swift
//  WatchKit Extension
//
//  Created by royal on 19/09/2020.
//

import SwiftUI
import Vulcan

struct GradesDetailView: View {
	let subject: Vulcan.SubjectGrades
	
	let colorizeGrades: Bool = UserDefaults.group.bool(forKey: UserDefaults.AppKeys.colorizeGrades.rawValue)
	let scheme: String = UserDefaults.group.string(forKey: UserDefaults.AppKeys.colorScheme.rawValue) ?? "Default"
	
	var body: some View {
		List(subject.grades) { grade in
			HStack {
				Text(LocalizedStringKey(grade.category?.name ?? "No category"))
					.font(.headline)
				Spacer()
				Text((grade.entry?.isReallyEmpty ?? true) ? "..." : grade.entry ?? "...")
			}
			.padding(.vertical)
			.coloredGrade(scheme: scheme, colorize: colorizeGrades, grade: grade.grade)
			.coloredListBackground(scheme: scheme, colorize: colorizeGrades, grade: grade.grade)
		}
		.listStyle(CarouselListStyle())
		.navigationTitle(subject.subject.name)
	}
}

/* struct GradesDetailView_Previews: PreviewProvider {
	static var previews: some View {
		GradesDetailView()
	}
} */

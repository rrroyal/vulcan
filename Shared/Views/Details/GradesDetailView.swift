//
//  GradesDetailView.swift
//  vulcan
//
//  Created by royal on 18/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan
import CoreData

struct GradesDetailView: View {
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	let subject: Vulcan.SubjectGrades
		
	@AppStorage(UserDefaults.AppKeys.colorScheme.rawValue, store: .group) var colorScheme: String = "Default"
	@AppStorage(UserDefaults.AppKeys.colorizeGrades.rawValue, store: .group) var colorizeGrades: Bool = true
	
	private var average: String? {
		let fetchRequest: NSFetchRequest<NSFetchRequestResult> = StoredEndOfTermPoints.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "subjectID == %i", subject.id)
		
		if let fetchResults: [StoredEndOfTermPoints] = try? CoreDataModel.shared.persistentContainer.viewContext.fetch(fetchRequest) as? [StoredEndOfTermPoints],
		   let entity = fetchResults.first {
			return entity.gradeAverage?.replacingOccurrences(of: ",", with: ".")
		}
		
		return nil
	}
	
	/// Refreshes the data
	private func fetch() {
		var shouldProvideErrorFeedback: Bool = false
		vulcan.getGrades() { error in
			if error != nil {
				shouldProvideErrorFeedback = true
			}
		}
		
		vulcan.getEndOfTermGrades() { error in
			if error != nil {
				shouldProvideErrorFeedback = true
			}
		}
		
		if shouldProvideErrorFeedback {
			UIDevice.current.generateHaptic(.error)
		}
	}
	
	/// Cell with average grade
	private var averageCell: some View {
		HStack {
			Text("Average")
				.bold()
			Spacer()
			Text(average ?? "")
				.bold()
				.coloredGrade(scheme: colorScheme, colorize: colorizeGrades, grade: Int(round(Float(average ?? "") ?? 0)))
		}
		.padding(.vertical, 10)
	}
	
	/// Cell with anticipated grade
	private var anticipatedGradeCell: some View {
		HStack {
			Text("Anticipated")
				.bold()
			Spacer()
			Text(vulcan.eotGrades.expected.first(where: { $0.subjectID == subject.subject.id })?.entry ?? "")
				.bold()
				.coloredGrade(scheme: colorScheme, colorize: colorizeGrades, grade: Int(vulcan.eotGrades.expected.first(where: { $0.subjectID == subject.subject.id })?.entry ?? ""))
		}
		.padding(.vertical, 10)
	}
	
	/// Cell with final grade
	private var finalGradeCell: some View {
		HStack {
			Text("Final")
				.bold()
			Spacer()
			Text(vulcan.eotGrades.final.first(where: { $0.subjectID == subject.subject.id })?.entry ?? "")
				.bold()
				.coloredGrade(scheme: colorScheme, colorize: colorizeGrades, grade: Int(vulcan.eotGrades.final.first(where: { $0.subjectID == subject.subject.id })?.entry ?? ""))
		}
		.padding(.vertical, 10)
	}
	
	var body: some View {
		List {
			// Grades
			Section {
				ForEach(subject.grades) { grade in
					GradeCell(scheme: colorScheme, colorize: colorizeGrades, grade: grade)
				}
			}
			
			// Final grades
			if (average != nil || vulcan.eotGrades.expected.first(where: { $0.subjectID == subject.subject.id }) != nil || vulcan.eotGrades.final.first(where: { $0.subjectID == subject.subject.id }) != nil) {
				Section {
					if (average != nil) {
						averageCell
					}
					
					// Anticipated
					if (vulcan.eotGrades.expected.first(where: { $0.subjectID == subject.subject.id }) != nil) {
						anticipatedGradeCell
					}
					
					// Final
					if (vulcan.eotGrades.final.first(where: { $0.subjectID == subject.subject.id }) != nil) {
						finalGradeCell
					}
				}
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text(subject.subject.name))
		.toolbar {
			// Refresh button
			ToolbarItem(placement: .navigationBarTrailing) {
				RefreshButton(loading: vulcan.dataState.grades.loading || vulcan.dataState.eotGrades.loading, iconName: "arrow.clockwise", edge: .trailing) {
					UIDevice.current.generateHaptic(.light)
					fetch()
				}
			}
		}
		.onAppear {
			vulcan.grades.first(where: { $0.subject.id == self.subject.id })?.hasNewItems = false
			
			if (AppState.shared.networkingMonitor.currentPath.isExpensive || vulcan.currentUser == nil) {
				return
			}
			
			if (!vulcan.dataState.eotGrades.fetched || (vulcan.dataState.eotGrades.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date())) {
				fetch()
			}
		}
	}
}

/* struct GradesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GradesDetailView()
    }
} */

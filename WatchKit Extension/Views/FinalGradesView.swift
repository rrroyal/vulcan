//
//  FinalGradesView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI
import Vulcan

struct FinalGradesView: View {
	@EnvironmentObject var vulcanStore: VulcanStore
	
	let colorizeGrades: Bool = UserDefaults.group.bool(forKey: UserDefaults.AppKeys.colorizeGrades.rawValue)
	let scheme: String = UserDefaults.group.string(forKey: UserDefaults.AppKeys.colorScheme.rawValue) ?? "Default"
	
    var body: some View {
		List {
			// Anticipated
			Section(header: Text("Anticipated")) {
				if (vulcanStore.eotGrades.expected.count > 0) {
					ForEach(vulcanStore.eotGrades.expected, id: \.subjectID) { grade in
						HStack {
							Text(grade.subject?.name ?? "Unknown subject")
								.font(.headline)
							Spacer()
							Text(grade.entry)
						}
						.padding(.vertical)
						.foregroundColor(colorizeGrades ? Color("ColorSchemes/\(scheme)/\(grade.entry)", bundle: Bundle(identifier: "Colors")) : .primary)
						.listRowPlatterColor(colorizeGrades ? Color("ColorSchemes/\(scheme)/\(grade.entry)", bundle: Bundle(identifier: "Colors")).opacity(0.25) : nil)
					}
				} else {
					Text("No grades")
						.multilineTextAlignment(.center)
						.opacity(0.3)
				}
			}
			
			// Final
			Section(header: Text("Final")) {
				if (vulcanStore.eotGrades.final.count > 0) {
					ForEach(vulcanStore.eotGrades.final, id: \.subjectID) { grade in
						HStack {
							Text(grade.subject?.name ?? "Unknown subject")
								.font(.headline)
							Spacer()
							Text(grade.entry)
						}
						.padding(.vertical)
						.foregroundColor(colorizeGrades ? Color("ColorSchemes/\(scheme)/\(grade.entry)", bundle: Bundle(identifier: "Colors")) : .primary)
						.listRowPlatterColor(colorizeGrades ? Color("ColorSchemes/\(scheme)/\(grade.entry)", bundle: Bundle(identifier: "Colors")).opacity(0.25) : nil)
					}
				} else {
					Text("No grades")
						.multilineTextAlignment(.center)
						.opacity(0.3)
				}
			}
		}
		.listStyle(PlainListStyle())
		.navigationBarTitle(Text("Final Grades"))
    }
}

struct FinalGradesView_Previews: PreviewProvider {
    static var previews: some View {
        FinalGradesView()
    }
}

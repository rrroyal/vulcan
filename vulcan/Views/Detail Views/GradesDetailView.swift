//
//  GradesDetailView.swift
//  vulcan
//
//  Created by royal on 18/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct GradesDetailView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@State var subject: Vulcan.Subject
	@State var grades: [Vulcan.Grade]
	@State var gradesAverage: Double?
	
    var body: some View {
		List {
			Section {
				ForEach(grades) { grade in
					GradeCell(grade: grade)
				}
			}
			
			if (self.gradesAverage != nil || self.VulcanAPI.endOfTermGrades.anticipated.first(where: { $0.subject == self.subject }) != nil || self.VulcanAPI.endOfTermGrades.final.first(where: { $0.subject == self.subject }) != nil) {
				Section {
					HStack {
						Text("Average")
							.bold()
						Spacer()
						Text(String(format: "%.2f", self.gradesAverage ?? 0))
							.bold()
							.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(Int(gradesAverage ?? 0))") : Color.primary)
					}
					.padding(.vertical, 10)
					.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(Int(gradesAverage ?? 0))").opacity(0.1) : nil)
					
					// Anticipated
					if (self.VulcanAPI.endOfTermGrades.anticipated.first(where: { $0.subject == self.subject }) != nil) {
						HStack {
							Text("Anticipated")
								.bold()
							Spacer()
							Text(String(self.VulcanAPI.endOfTermGrades.anticipated.first(where: { $0.subject == self.subject })?.grade ?? 0))
								.bold()
								.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(self.VulcanAPI.endOfTermGrades.anticipated.first(where: { $0.subject == self.subject })?.grade ?? 0)") : Color.primary)
						}
						.padding(.vertical, 10)
						.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(self.VulcanAPI.endOfTermGrades.anticipated.first(where: { $0.subject == self.subject })?.grade ?? 0)").opacity(0.1) : nil)
					}
					
					// Final
					if (self.VulcanAPI.endOfTermGrades.final.first(where: { $0.subject == self.subject }) != nil) {
						HStack {
							Text("Final")
								.bold()
							Spacer()
							Text(String(self.VulcanAPI.endOfTermGrades.final.first(where: { $0.subject == self.subject })?.grade ?? 0))
								.bold()
								.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(self.VulcanAPI.endOfTermGrades.final.first(where: { $0.subject == self.subject })?.grade ?? 0)") : Color.primary)
						}
						.padding(.vertical, 10)
						.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(self.VulcanAPI.endOfTermGrades.final.first(where: { $0.subject == self.subject })?.grade ?? 0)").opacity(0.1) : nil)
					}
				}
				.loadingOverlay(self.VulcanAPI.dataState.eotGrades.loading)
			}
		}
		.listStyle(GroupedListStyle())
		.environment(\.horizontalSizeClass, .regular)
		.navigationBarTitle(Text(subject.name))
		.navigationBarItems(trailing: Button(action: {
			generateHaptic(.light)
			self.VulcanAPI.getEOTGrades() { success, error in
				if (error != nil) {
					generateHaptic(.error)
				}
			}
		}, label: {
			Image(systemName: "arrow.clockwise")
				.navigationBarButton(edge: .trailing)
		}))
		.onAppear {
			var sum: Int = 0
			
			if (self.grades.count > 0) {
				self.gradesAverage = 0
				
				self.grades.forEach { grade in
					if (grade.value != nil) {
						self.gradesAverage! += (grade.value ?? Double(grade.actualGrade) * grade.weight) + grade.weightModificator
						sum += grade.gradeWeight						
					}
				}
				self.gradesAverage = (self.gradesAverage! / Double(sum))
			}
			
			if (!self.VulcanAPI.dataState.eotGrades.fetched) {
				self.VulcanAPI.getEOTGrades() { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
		}
    }
}

/* struct GradesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GradesDetailView()
    }
} */

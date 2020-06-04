//
//  DebugView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct DebugView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore

    var body: some View {
		List {
			// Settings
			Section(header: Text("Settings")) {
				// isLoggedIn
				Text("isLoggedIn: \(UserDefaults.user.isLoggedIn ? "true" : "false")")
				
				// userGroup
				Text("userGroup: \(UserDefaults.user.userGroup)")
				
				// colorizeGrades
				Text("colorizeGrades: \(UserDefaults.user.colorizeGrades ? "true" : "false")")
				
				// colorScheme
				Text("colorScheme: \(UserDefaults.user.colorScheme)")
			}
			
			// Data
			Section(header: Text("Data")) {
				// Schedule
				Text("Schedule: \(self.VulcanStore.schedule.count)")
				
				// Grades
				Text("Grades: \(self.VulcanStore.grades.count)")
				
				// EOT Grades
				Text("EOT Ant.: \(self.VulcanStore.endOfTermGrades.anticipated.count)")
				Text("EOT Fin.: \(self.VulcanStore.endOfTermGrades.final.count)")
				
				// Tasks
				Text("Exams: \(self.VulcanStore.tasks.exams.count)")
				Text("Homework: \(self.VulcanStore.tasks.homework.count)")
			}
		}
		.listStyle(PlainListStyle())
		.navigationBarTitle(Text("Debug"))
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}

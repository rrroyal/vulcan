//
//  GradesDetailView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct GradesDetailView: View {
	let subjectName: String
	let grades: [Vulcan.Grade]
	
    var body: some View {
		List {
			ForEach(grades) { grade in
				HStack {
					Text(LocalizedStringKey(grade.category?.name ?? "No category"))
						.font(.headline)
					Spacer()
					Text(grade.value == nil ? "..." : grade.entry)
				}
				.padding(.vertical)
				.listRowPlatterColor(UserDefaults.user.colorizeGrades ? Color.fromScheme(value: Int(grade.actualGrade)).opacity(0.25) : nil)
			}
		}
		.navigationBarTitle(Text(subjectName))
    }
}

/* struct GradesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GradesDetailView()
    }
} */

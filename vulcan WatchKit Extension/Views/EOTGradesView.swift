//
//  EOTGradesView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct EOTGradesView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
	var body: some View {
		List {
			// Anticipated
			Section(header: Text("Anticipated")) {
				ForEach(self.VulcanStore.endOfTermGrades.anticipated, id: \.subject.id) { grade in
					HStack {
						Text(grade.subject.name)
							.font(.headline)
						Spacer()
						Text("\(grade.grade)")
					}
					.padding(.vertical)
					.listRowPlatterColor(UserDefaults.user.colorizeGrades ? Color.fromScheme(value: grade.grade).opacity(0.25) : nil)
				}
			}
			
			// Final
			Section(header: Text("Final")) {
				ForEach(self.VulcanStore.endOfTermGrades.final, id: \.subject.id) { grade in
					HStack {
						Text(grade.subject.name)
							.font(.headline)
						Spacer()
						Text("\(grade.grade)")
					}
					.padding(.vertical)
					.listRowPlatterColor(UserDefaults.user.colorizeGrades ? Color.fromScheme(value: grade.grade).opacity(0.25) : nil)
				}
			}
		}
		.listStyle(PlainListStyle())
		.navigationBarTitle(Text("Final grades"))
	}
}

struct EOTGradesView_Previews: PreviewProvider {
    static var previews: some View {
        EOTGradesView()
    }
}

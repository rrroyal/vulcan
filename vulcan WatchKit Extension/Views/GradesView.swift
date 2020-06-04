//
//  GradesView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct GradesView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
	var body: some View {
		List {
			ForEach(self.VulcanStore.grades) { subject in
				NavigationLink(destination: GradesDetailView(subjectName: subject.subject.name, grades: subject.grades)) {
					Text(subject.subject.name)
				}
				.padding(.vertical)
			}
		}
		.navigationBarTitle(Text("Grades"))
	}
}

struct GradesView_Previews: PreviewProvider {
    static var previews: some View {
        GradesView()
    }
}

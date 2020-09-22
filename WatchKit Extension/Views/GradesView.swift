//
//  GradesView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI
import Vulcan

struct GradesView: View {
	@ObservedObject var vulcanStore: VulcanStore = VulcanStore.shared
	
    var body: some View {
		Group {
			if (vulcanStore.grades.count > 0) {
				List(vulcanStore.grades) { subject in
					NavigationLink(destination: GradesDetailView(subject: subject)) {
						VStack(alignment: .leading) {
							Text(subject.subject.name)
								.font(.headline)
							
							Text("\(subject.employee.name) \(subject.employee.surname)")
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						.padding(.vertical)
					}
				}
				.listStyle(CarouselListStyle())
			} else {
				Text("No grades")
					.multilineTextAlignment(.center)
					.opacity(0.3)
			}
		}
		.navigationTitle(Text("Grades"))
    }
}

struct GradesView_Previews: PreviewProvider {
    static var previews: some View {
        GradesView()
    }
}

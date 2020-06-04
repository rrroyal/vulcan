//
//  TasksView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct TasksView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
	var body: some View {
		List {
			Section(header: Text("Homework")) {
				ForEach(self.VulcanStore.tasks.homework) { task in
					VStack(alignment: .leading) {
						Text(task.description)
							.font(.headline)
						Text("\(task.subject.name), \(task.date.formattedString(format: "dd/MM/yyyy"))")
					}
					.opacity(task.date > Date() ? 1 : 0.25)
					.padding(.vertical)
				}
			}
			
			Section(header: Text("Exams")) {
				ForEach(self.VulcanStore.tasks.exams) { task in
					VStack(alignment: .leading) {
						Text(task.description)
							.font(.headline)
						Text("\(task.subject.name), \(task.date.formattedString(format: "dd/MM/yyyy"))")
					}
					.opacity(task.date > Date() ? 1 : 0.25)
					.padding(.vertical)
				}
			}
		}
		.listStyle(PlainListStyle())
		.navigationBarTitle(Text("Tasks"))
	}
}

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
    }
}

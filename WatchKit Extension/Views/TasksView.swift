//
//  TasksView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI

struct TasksView: View {
	@EnvironmentObject var vulcanStore: VulcanStore
	
    var body: some View {
		List {
			Section(header: Text("Homework")) {
				if (vulcanStore.tasks.homework.count > 0) {
					ForEach(vulcanStore.tasks.homework) { task in
						VStack(alignment: .leading) {
							Text(task.entry)
								.font(.headline)
							
							if let subjectName = task.subject?.name {
								Text("\(subjectName), \(task.date.formattedString(format: "dd/MM/yyyy"))")
							} else {
								Text(task.date.formattedString(format: "dd/MM/yyyy"))
							}
						}
						.opacity(task.date > Date() ? 1 : 0.5)
						.padding(.vertical)
					}
				} else {
					Text("Nothing found")
						.multilineTextAlignment(.center)
						.opacity(0.3)
				}
			}
			
			Section(header: Text("Exams")) {
				if (vulcanStore.tasks.exams.count > 0) {
					ForEach(vulcanStore.tasks.exams) { task in
						VStack(alignment: .leading) {
							Text(task.entry)
								.font(.headline)
							
							if let subjectName = task.subject?.name {
								Text("\(subjectName), \(task.date.formattedString(format: "dd/MM/yyyy"))")
							} else {
								Text(task.date.formattedString(format: "dd/MM/yyyy"))
							}
						}
						.opacity(task.date > Date() ? 1 : 0.5)
						.padding(.vertical)
					}
				} else {
					Text("Nothing found")
						.multilineTextAlignment(.center)
						.opacity(0.3)
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

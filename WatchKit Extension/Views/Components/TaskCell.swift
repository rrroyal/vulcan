//
//  TaskCell.swift
//  WatchKit Extension
//
//  Created by Kacper on 20/09/2020.
//

import SwiftUI
import Vulcan

struct TaskCell: View {
	let task: VulcanTask
	let type: Bool?
	
	var body: some View {
		VStack(alignment: .leading) {
			Group {
				if !task.entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					Text(task.entry)
				} else {
					Text("No entry")
						.foregroundColor(.secondary)
				}
			}
			.font(.headline)
			.multilineTextAlignment(.leading)
			.allowsTightening(true)
			.lineLimit(5)
			
			Group {
				if let subjectName = task.subject?.name {
					Text(subjectName)
				}
				
				if let type = type {
					Text("\(NSLocalizedString(type ? "EXAM_BIG" : "EXAM_SMALL", comment: "")) • \(task.date.relativeString)")
				} else {
					Text(task.date.relativeString)
				}
			}
			.font(.callout)
			.foregroundColor(.secondary)
			.multilineTextAlignment(.leading)
			.allowsTightening(true)
			.lineLimit(3)
		}
		.padding(.vertical, 10)
		.opacity(task.date >= Date() ? 1 : 0.75)
	}
}


/* struct TaskCell_Previews: PreviewProvider {
    static var previews: some View {
        TaskCell()
    }
} */

//
//  TaskCell.swift
//  WatchKit Extension
//
//  Created by royal on 20/09/2020.
//

import SwiftUI
import Vulcan

struct TaskCell: View {
	let task: VulcanTask
	let isBigType: Bool?
	
	var body: some View {
		VStack(alignment: .leading) {
			Group {
				if !task.entry.isReallyEmpty {
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
				
				if let isBigType = isBigType {
					Text("\((isBigType ? "EXAM_BIG" : "EXAM_SMALL").localized) • \(task.date.relativeString)")
				} else {
					Text(task.date, style: .relative)
				}
			}
			.font(.callout)
			.foregroundColor(.secondary)
			.multilineTextAlignment(.leading)
			.allowsTightening(true)
			.lineLimit(3)
		}
		.padding(.vertical, 10)
		.opacity(task.date.endOfDay >= Date() ? 1 : 0.75)
	}
}


/* struct TaskCell_Previews: PreviewProvider {
    static var previews: some View {
        TaskCell()
    }
} */

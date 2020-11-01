//
//  TaskCell.swift
//  vulcan
//
//  Created by royal on 26/06/2020.
//

import SwiftUI
import Vulcan

struct TaskCell: View {
	let task: VulcanTask
	let isBigType: Bool?
	
    var body: some View {
		VStack(alignment: .leading, spacing: 4) {
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
			.lineLimit(nil)
			
			Group {
				if let subjectName = task.subject?.name,
				   let employeeName = task.employee?.name,
				   let employeeSurname = task.employee?.surname {
					Text("\(subjectName) - \(employeeName) \(employeeSurname)")
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
		.opacity(task.date.endOfDay >= Date() ? 1 : 0.5)
		.contextMenu {
			// Reminders
			Button(action: {
				generateHaptic(.light)
				task.addToReminders(isBigType: isBigType)
			}) {
				Label("Add to reminders", systemImage: "bell.fill")
			}
			
			// Calendar
			Button(action: {
				generateHaptic(.light)
				task.addToCalendar(isBigType: isBigType)
			}) {
				Label("Add to calendar", systemImage: "calendar.badge.plus")
			}
		}
    }
}

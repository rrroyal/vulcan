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
	
    var body: some View {
		VStack(alignment: .leading, spacing: 4) {
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
			.lineLimit(nil)
			
			Group {
				if let subjectName = task.subject?.name,
				   let employeeName = task.employee?.name,
				   let employeeSurname = task.employee?.surname {
					Text("\(subjectName) - \(employeeName) \(employeeSurname)")
				}
				
				Text("\(NSLocalizedString(task.tag.rawValue, comment: "")) • \(task.date.formattedDateString(timeStyle: .none, dateStyle: .full, context: .beginningOfSentence))")
			}
			.font(.callout)
			.foregroundColor(.secondary)
			.multilineTextAlignment(.leading)
			.allowsTightening(true)
			.lineLimit(3)
		}
		.padding(.vertical, 10)
		.opacity(task.date >= Date() ? 1 : 0.75)
		.contextMenu {
			// Reminders
			Button(action: {
				generateHaptic(.light)
				task.addToReminders()
			}) {
				Label("Add to reminders", systemImage: "bell.fill")
			}
			
			// Calendar
			Button(action: {
				generateHaptic(.light)
				task.addToCalendar()
			}) {
				Label("Add to calendar", systemImage: "calendar.badge.plus")
			}
		}
    }
}

//
//  NoteCell.swift
//  vulcan
//
//  Created by royal on 07/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan

struct NoteCell: View {
	let note: Vulcan.Note
	
    var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(note.entry)
				.font(.headline)
				.allowsTightening(true)
				.minimumScaleFactor(0.8)
				.lineLimit(nil)
			
			if let employeeName = note.employee?.name,
			   let employeeSurname = note.employee?.surname {
				Group {
					if let categoryName = note.category?.name {
						Text("\(employeeName) \(employeeSurname): \(categoryName) • \(note.date.formattedDateString(timeStyle: .none, dateStyle: .medium))")
					} else {
						Text("\(employeeName) \(employeeSurname) • \(note.date.formattedDateString(timeStyle: .none, dateStyle: .medium))")
					}
				}
				.foregroundColor(.secondary)
				.multilineTextAlignment(.leading)
				.allowsTightening(true)
				.minimumScaleFactor(0.9)
				.lineLimit(5)
			}
		}
		.padding(.vertical, 10)
		.contextMenu {
			// Copy
			Button(action: {
				var string: String = ""
				string += "Od: \(note.employee?.name ?? "Unknown employee") \(note.employee?.surname ?? "")\n"
				string += "Data: \(note.date.formattedString(format: "yyyy-MM-dd HH:mm:ss"))\n\n"
				string += note.entry
				generateHaptic(.light)
				UIPasteboard.general.string = string.trimmingCharacters(in: .whitespacesAndNewlines)
			}) {
				Text("Copy")
				Spacer()
				Image(systemName: "doc.on.doc")
			}
		}
    }
}

/* struct NoteCell_Previews: PreviewProvider {
    static var previews: some View {
        NoteCell()
    }
} */

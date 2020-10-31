//
//  GradeCell.swift
//  vulcan
//
//  Created by royal on 30/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan

struct GradeCell: View {
	let scheme: String
	let colorize: Bool
	let grade: Vulcan.Grade
	
	var body: some View {
		HStack {
			// Grade entry
			Text((grade.entry?.isEmpty ?? true) ? "..." : (grade.entry ?? "..."))
				.font(.title)
				.bold()
				.padding(.trailing)
				.opacity(grade.value == nil ? 0.5 : 1)
				.coloredGrade(scheme: scheme, colorize: colorize, grade: grade.grade)
			
			// New grade indicator
			/* if (!grade.seen) {
				Image(systemName: "staroflife.fill")
					.opacity(0.35)
			} */
			
			// Spacing
			Spacer(minLength: 20)
			
			// Grade details
			VStack(alignment: .trailing, spacing: 4) {
				Group {
					Group {
						if let description = grade.description {
							Text(LocalizedStringKey(description.isEmpty ? "No description" : description))
						} else {
							Text(LocalizedStringKey("No description"))
						}
					}
					.font(.headline)
					.foregroundColor((grade.description?.isEmpty ?? true) ? Color.secondary : Color.primary)
					
					Group {
						if let category = grade.category {
							if let comment = grade.comment {
								Text(comment)
							}
							
							if let weight = grade.weight?.replacingOccurrences(of: ",", with: ".") {
								Text("\(category.name ?? "Unknown category") • \(weight)")
							} else {
								Text(category.name ?? "Unknown category")
							}
							
							Text(grade.dateCreated.formattedDateString(timeStyle: .none, dateStyle: .full, context: .beginningOfSentence))
						} else {
							// Comment
							if let comment = grade.comment {
								Text(comment)
							}
							
							// Weight, date
							if let weight = grade.weight?.replacingOccurrences(of: ",", with: ".") {
								Text("\(weight) • \(grade.dateCreated.formattedDateString(timeStyle: .none, dateStyle: .full, context: .beginningOfSentence))")
							} else {
								Text(grade.dateCreated.formattedDateString(timeStyle: .none, dateStyle: .full, context: .beginningOfSentence))
							}
						}
					}
					.font(.callout)
					.foregroundColor(.secondary)
				}
				.multilineTextAlignment(.trailing)
				.allowsTightening(true)
				.minimumScaleFactor(0.5)
				.lineLimit(3)
			}
		}
		.padding(.vertical, 10)
	}
}

/* struct GradeCell_Previews: PreviewProvider {
    static var previews: some View {
        GradeCell()
    }
} */

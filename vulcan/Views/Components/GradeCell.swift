//
//  GradeCell.swift
//  vulcan
//
//  Created by royal on 30/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct GradeCell: View {
	let grade: Vulcan.Grade
	
    var body: some View {
		HStack {
			Text(grade.value == nil ? "..." : grade.entry)
				.font(.largeTitle)
				.bold()
				.foregroundColor(UserDefaults.user.colorizeGrades ? Color.fromScheme(value: Int(grade.actualGrade)) : Color.primary)
			
			Spacer(minLength: 20)
			
			VStack(alignment: .trailing) {
				Group {
					Text(LocalizedStringKey(grade.description))
						.font(.headline)
						.padding(.bottom, 2)
					
					Group {
						if (grade.category != nil) {
							Text("\(grade.category?.name ?? "") • \(String(format: "%.2f", grade.weight))")
								.padding(.bottom, 2)
							if (!(grade.comment?.isEmpty ?? true)) {
								Text(grade.comment ?? "")
									.padding(.bottom, 2)
							}
							Text(grade.date.formattedString(format: "EEEE, d MMMM yyyy").capitalingFirstLetter())
						} else {
							if (!(grade.comment?.isEmpty ?? true)) {
								Text(grade.comment ?? "")
									.padding(.bottom, 2)
							}
							Text("\(String(format: "%.2f", grade.weight)) • \(grade.date.formattedString(format: "EEEE, d MMMM yyyy").capitalingFirstLetter())")
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
		.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color.fromScheme(value: Int(grade.actualGrade)).opacity(0.1) : nil)
    }
}

/* struct GradeCell_Previews: PreviewProvider {
    static var previews: some View {
        GradeCell()
    }
} */

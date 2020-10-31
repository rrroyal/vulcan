//
//  FinalGradeCell.swift
//  vulcan
//
//  Created by royal on 07/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Vulcan

struct FinalGradeCell: View {
	let scheme: String
	let colorize: Bool
	let grade: Vulcan.EndOfTermGrade
	
    var body: some View {
		HStack {
			Text(grade.subject?.name ?? "Unknown subject (\(grade.subjectID))")
				.bold()
				.lineLimit(2)
				.allowsTightening(true)
				.minimumScaleFactor(0.9)
			Spacer()
			Text(grade.entry)
				.bold()
				.coloredGrade(scheme: scheme, colorize: colorize, grade: Int(grade.entry))
				.padding(.leading)
		}
		.padding(.vertical, 10)
    }
}

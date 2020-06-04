//
//  Color.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

// MARK: - Color
extension Color {
	static var mainColor: Color = Color("mainColor", bundle: Bundle(identifier: "Colors"))
	static func fromScheme(value: Int) -> Color {
		return Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(value)", bundle: Bundle(identifier: "Colors"))
	}
}

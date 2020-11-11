//
//  View.swift
//  Harbour
//
//  Created by royal on 15/03/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

// MARK: - View
extension View {
	func buttonModifier(color: Color, solid: Bool = true) -> some View {
		return self
			.padding()
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
			.background(solid ? color : color.opacity(0.2))
			.foregroundColor(solid ? Color.white : color)
			.font(.headline)
			.cornerRadius(12)
	}
	
	@ViewBuilder
	func coloredGrade(scheme: String, colorize: Bool, grade: Int?) -> some View {		
		if colorize,
		   let uiColor = UIColor(named: "ColorSchemes/\(scheme)/\(grade ?? 0)") {
			self
				.foregroundColor(Color(uiColor))
		} else {
			self
				.foregroundColor(Color.primary)
		}
	}
	
	@ViewBuilder
	func coloredListBackground(scheme: String, colorize: Bool, grade: Int?) -> some View {
		if colorize,
		   let uiColor = UIColor(named: "ColorSchemes/\(scheme)/\(grade ?? 0)") {
			#if os(iOS) || os(macOS)
			self
				.listRowBackground(Color(uiColor))
			#elseif os(watchOS)
			self
				.listRowPlatterColor(Color(uiColor))
			#endif
		} else {
			self
		}
	}
	
	@ViewBuilder
	func loadingOverlay(_ loading: Bool, fadeAmount: Double = 0.9) -> some View {
		if (loading) {
			self
				.opacity(loading ? 1 - fadeAmount : 1)
				.overlay(ProgressView())
		} else {
			self
		}
	}
	
	func navigationBarButton(edge: Edge.Set) -> some View {
		return self
			.padding([.vertical, edge == .leading ? .trailing : .leading])
			.padding(edge, 5)
			.font(.system(size: 20))
	}
	
	/// Makes the view full width.
	func fullWidth(alignment: Alignment = .center) -> some View {
		return self.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
	}
}

// MARK: - Text
extension Text {
	func bold(_ useBold: Bool = true) -> Text {
		if (useBold) {
			return self.bold()
		} else {
			return self
		}
	}
	
	func sectionTitle() -> some View {
		return self
			.font(.title2)
			.bold()
			.opacity(1)
			.foregroundColor(Color.primary)
			.textCase(.none)
	}
}

// MARK: - ForEach
extension ForEach where Content: View {
	@ViewBuilder
	func onDelete(enabled: Bool, perform action: @escaping (IndexSet) -> Void) -> some View {
		if (enabled) {
			self.onDelete(perform: action)
		} else {
			self
		}
	}
}

//
//  View.swift
//  vulcan
//
//  Created by royal on 06/07/2020.
//

import SwiftUI
import Combine

// MARK: - List
extension List {
	@ViewBuilder
	func sidebarListStyle(horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
		#if os(iOS)
		if (horizontalSizeClass == .compact) {
			self
				.listStyle(InsetGroupedListStyle())
		} else {
			self
				.listStyle(SidebarListStyle())
		}
		#else
		self
			.listStyle(SidebarListStyle())
			.frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
		#endif
	}
}

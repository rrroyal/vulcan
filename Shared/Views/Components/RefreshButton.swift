//
//  RefreshButton.swift
//  vulcan
//
//  Created by royal on 25/06/2020.
//

import SwiftUI

struct RefreshButton: View {
	internal init(loading: Bool, progressValue: Double? = nil, iconName: String, edge: Edge.Set, perform action: @escaping () -> Void) {
		self.loading = loading
		self.progressValue = progressValue
		self.iconName = iconName
		self.edge = edge
		self.action = action
	}
	
	var loading: Bool
	var progressValue: Double?
	var iconName: String
	var edge: Edge.Set
	var action: () -> Void
	
	var body: some View {
		Group {
			if loading {
				ProgressView(value: progressValue)
			} else {
				Button(action: action) {
					Image(systemName: iconName)
				}
			}
		}
		// .transition(.opacity)
		// .animation(.easeInOut)
		// .frame(width: 22.5)
		.navigationBarButton(edge: edge)
	}
}

/* struct RefreshButton_Previews: PreviewProvider {
    static var previews: some View {
        RefreshButton()
    }
} */

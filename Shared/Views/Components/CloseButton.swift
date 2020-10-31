//
//  CloseButton.swift
//  vulcan
//
//  Created by royal on 27/06/2020.
//

import SwiftUI

struct CloseButton: View {
	let action: () -> Void
	
	init(perform action: @escaping () -> Void) {
		self.action = action
	}
	
    var body: some View {
        Circle()
			.fill(Color(UIColor.systemGray5))
			.overlay(
				Image(systemName: "xmark")
					.font(.system(size: 16, weight: .semibold))
					.foregroundColor(Color(UIColor.systemGray))
			)
			.frame(width: 26, height: 26)
			.onTapGesture(perform: action)
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
		CloseButton(perform: {})
			.previewLayout(.sizeThatFits)
    }
}

//
//  AppIconView.swift
//  iOS
//
//  Created by Kacper on 21/09/2020.
//

import SwiftUI

/// View showing list of available app icons.
struct AppIconView: View {	
	var body: some View {
		List(Bundle.main.appIcons, id: \.self) { (icon) in
			HStack {
				Image(icon)
					.cornerRadius(16)
				
				Spacer()
				
				if (Bundle.main.currentAppIcon == icon) {
					Image(systemName: "checkmark")
						.font(.headline)
				}
			}
			.id(icon)
			.padding(.vertical, 10)
			.contentShape(Rectangle())
			.onTapGesture {
				if (Bundle.main.currentAppIcon != icon) {
					generateHaptic(.light)
				}
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("App Icon"))
	}
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
    }
}

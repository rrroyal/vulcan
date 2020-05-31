//
//  ColorSchemeSettingsView.swift
//  vulcan
//
//  Created by royal on 19/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ColorSchemeSettingsView: View {
	@EnvironmentObject var Settings: SettingsModel
	
    var body: some View {
		List(Bundle.main.colorSchemes, id: \.self) { scheme in
			HStack {
				VStack(alignment: .leading) {
					Text(LocalizedStringKey(scheme))
						.font(.headline)
						.padding(.bottom, 2)
					
					HStack {
						Text("6").foregroundColor(Color("ColorSchemes/\(scheme)/6"))
						Text("5").foregroundColor(Color("ColorSchemes/\(scheme)/5"))
						Text("4").foregroundColor(Color("ColorSchemes/\(scheme)/4"))
						Text("3").foregroundColor(Color("ColorSchemes/\(scheme)/3"))
						Text("2").foregroundColor(Color("ColorSchemes/\(scheme)/2"))
						Text("1").foregroundColor(Color("ColorSchemes/\(scheme)/1"))
						Text("-").foregroundColor(Color("ColorSchemes/\(scheme)/0"))
					}
				}
				
				Spacer()
				
				if (self.Settings.colorScheme == scheme) {
					Image(systemName: "checkmark")
						.font(.headline)
				}
			}
			.contentShape(Rectangle())
			.onTapGesture {
				self.Settings.colorScheme = scheme
				generateHaptic(.light)
			}
		}
		.listStyle(GroupedListStyle())
		.environment(\.horizontalSizeClass, .regular)
		.navigationBarTitle(Text("Color Scheme"))
    }
}

/* struct ColorSchemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSchemeSettingsView()
    }
} */

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
						Text("6").foregroundColor(Color("ColorSchemes/\(scheme)/6", bundle: Bundle(identifier: "Colors")))
						Text("5").foregroundColor(Color("ColorSchemes/\(scheme)/5", bundle: Bundle(identifier: "Colors")))
						Text("4").foregroundColor(Color("ColorSchemes/\(scheme)/4", bundle: Bundle(identifier: "Colors")))
						Text("3").foregroundColor(Color("ColorSchemes/\(scheme)/3", bundle: Bundle(identifier: "Colors")))
						Text("2").foregroundColor(Color("ColorSchemes/\(scheme)/2", bundle: Bundle(identifier: "Colors")))
						Text("1").foregroundColor(Color("ColorSchemes/\(scheme)/1", bundle: Bundle(identifier: "Colors")))
						Text("-").foregroundColor(Color("ColorSchemes/\(scheme)/0", bundle: Bundle(identifier: "Colors")))
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

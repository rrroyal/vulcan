//
//  ColorSchemeSettingsView.swift
//  iOS
//
//  Created by Kacper on 21/09/2020.
//

import SwiftUI

/// View showing list of available color schemes.
struct ColorSchemeSettingsView: View {
	@AppStorage(UserDefaults.AppKeys.colorScheme.rawValue, store: .group) var colorScheme: String = "Default"
	
	var body: some View {
		List(Bundle.main.colorSchemes, id: \.self) { (scheme) in
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
				
				if colorScheme == scheme {
					Image(systemName: "checkmark")
						.font(.headline)
						.foregroundColor(.accentColor)
				}
			}
			.id(scheme)
			.padding(.vertical, 10)
			.contentShape(Rectangle())
			.onTapGesture {
				colorScheme = scheme
				generateHaptic(.light)
			}
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Color Scheme"))
	}
}

struct ColorSchemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSchemeSettingsView()
    }
}

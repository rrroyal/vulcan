//
//  AppIconView.swift
//  iOS
//
//  Created by royal on 21/09/2020.
//

import SwiftUI

/// View showing list of available app icons.
struct AppIconView: View {
	@State var currentIcon = Bundle.main.currentAppIconName
	
	let imageSize: CGFloat = 86
	let cornerRadius: CGFloat = 20
	
	var currentlySelectedOverlay: some View {
		Color(UIColor.systemBackground)
			.opacity(0.9)
			.overlay(
				Image(systemName: "checkmark")
					.font(.headline)
					.foregroundColor(.primary)
			)
	}
	
	var body: some View {
		ScrollView {
			LazyVGrid(columns: [GridItem(.adaptive(minimum: imageSize), spacing: 10)]) {
				ForEach(Bundle.main.appIcons, id: \.self) { icon in
					Image(uiImage: icon == "Default" ? (Bundle.main.currentAppIconImage ?? UIImage(systemName: "questionmark") ?? UIImage()) : UIImage(imageLiteralResourceName: "\(icon)@2x.png"))
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: imageSize, height: imageSize)
						.overlay(currentlySelectedOverlay.opacity(currentIcon == icon ? 1 : 0))
						.cornerRadius(cornerRadius)
						.onTapGesture {
							if Bundle.main.currentAppIconName == icon {
								print("YUP")
								return
							}
							
							generateHaptic(.light)
							UIApplication.shared.setAlternateIconName(icon == "Default" ? nil : icon) { error in
								if let error = error {
									AppState.shared.logger.error("Error setting alternative icon: \(error.localizedDescription)")
								} else {
									withAnimation {
										currentIcon = icon
									}
								}
							}
						}
						.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 0)
						.padding()
				}
			}
			.padding(.horizontal)
		}
		.navigationTitle(Text("App Icon"))
	}
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
    }
}

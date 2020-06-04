//
//  UI.swift
//  Harbour
//
//  Created by royal on 15/03/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// Modifies button to our custom style
struct ButtonModifier: ViewModifier {
	var style: Color
	
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style))
            .padding(.bottom)
    }
}

/// Modifies button to our custom style
struct NavigationBarButtonModifier: ViewModifier {
	var edge: Edge.Set
	
	func body(content: Content) -> some View {
		content
			.padding([.vertical, edge == .leading ? .trailing : .leading])
			.padding(edge, 5)
			.font(.system(size: 20))
	}
}

// MARK: - View
extension View {
	func customButton(_ style: Color) -> ModifiedContent<Self, ButtonModifier> {
		return modifier(ButtonModifier(style: style))
    }
	
	func navigationBarButton(edge: Edge.Set) -> ModifiedContent<Self, NavigationBarButtonModifier> {
		return modifier(NavigationBarButtonModifier(edge: edge))
	}
	
	func loadingOverlay(_ loading: Bool, fadeAmount: Double = 0.9) -> some View {
			self
				.opacity(loading ? (1 - fadeAmount) : 1)
				.overlay(
					VStack {
						ActivityIndicator(isAnimating: .constant(loading), style: .medium)
							.opacity(loading ? 1 : 0)
							.animation(.easeInOut)
							.transition(.opacity)
					}
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
					.edgesIgnoringSafeArea(.all)
				)
				.animation(.easeInOut)
				.transition(.opacity)
				// .allowsHitTesting(loading)
	}
	
	func dynamicNavigationViewStyle(useFullscreen: Bool) -> AnyView {
        if (useFullscreen) {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self.navigationViewStyle(DefaultNavigationViewStyle()))
        }
    }
}

// MARK: - Text
extension Text {
	func customTitleText() -> Text {
		self
			.fontWeight(.bold)
			.font(.system(size: 32))
	}
	
	func bold(_ useBold: Bool = true) -> Text {
		if (useBold) {
			return self.bold()
		} else {
			return self
		}
	}
}

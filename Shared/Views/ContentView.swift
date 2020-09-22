//
//  ContentView.swift
//  Shared
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan

/// Main view
struct ContentView: View {
	@Binding var currentTab: Tab
	
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	
	@State private var isOnboardingVisible: Bool = false
	@State private var isNotificationVisible: Bool = false
	
	/// Runs after the view displays (which is shortly after the initialization) and displays the onboarding.
	private func loadView() {
		if (!SettingsModel.shared.launchedBefore) {
			isOnboardingVisible = true
		}
	}
	
	@ViewBuilder var body: some View {
		Group {
			#if os(iOS)
			AppTabNavigation(currentTab: $currentTab)
			#else
			AppSidebarNavigation()
			#endif
		}
		.sheet(isPresented: $isOnboardingVisible, onDismiss: {
			SettingsModel.shared.launchedBefore = true
		}) {
			OnboardingView(isPresented: $isOnboardingVisible)
		}
		.onAppear(perform: loadView)
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(currentTab: .constant(.home))
    }
}

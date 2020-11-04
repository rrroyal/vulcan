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
	@ObservedObject var appState: AppState
	
	/* #if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif */
	
	@State private var isOnboardingVisible: Bool = !SettingsModel.shared.launchedBefore
	@State private var isNotificationVisible: Bool = false
	
	@ViewBuilder var body: some View {
		Group {
			#if os(iOS)
			/* if horizontalSizeClass == .compact {
				AppTabNavigation(appState: appState)
			} else {
				AppSidebarNavigation()
			} */
			AppTabNavigation(appState: appState)
			#else
			AppSidebarNavigation(appState: appState)
			#endif
		}
		.sheet(isPresented: $isOnboardingVisible, onDismiss: {
			SettingsModel.shared.launchedBefore = true
		}) {
			OnboardingView(isPresented: $isOnboardingVisible)
		}
		/* .onAppear {
			if !SettingsModel.shared.launchedBefore {
				isOnboardingVisible = true
			}
		} */
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(appState: AppState.shared)
    }
}

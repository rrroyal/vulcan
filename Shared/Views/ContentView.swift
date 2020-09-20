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
	@EnvironmentObject var appState: AppState
	@EnvironmentObject var vulcan: Vulcan
	@EnvironmentObject var settings: SettingsModel
	
	@Binding var currentTab: Tab
	
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	
	@State private var isOnboardingVisible: Bool = false
	@State private var isNotificationVisible: Bool = false
	
	/// Runs after the view displays (which is shortly after the initialization) and displays the onboarding.
	private func loadView() {
		if (!settings.launchedBefore) {
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
			settings.launchedBefore = true
		}) {
			OnboardingView(isPresented: $isOnboardingVisible)
				.environmentObject(vulcan)
		}
		.onAppear(perform: loadView)
		/* .onReceive(appDelegate?.notificationPublisher) { (data) in
			self.isNotificationVisible = data
			/* if (data && notificationData.autodismisses) {
				instantiateTimer()
			} */
		} */
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(currentTab: .constant(.home))
    }
}

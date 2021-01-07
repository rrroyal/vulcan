//
//  NotificationsOverlay.swift
//  
//
//  Created by royal on 10/07/2020.
//

#if !WIDGET
import SwiftUI
import Combine
import os

#if os(iOS)
import CoreHaptics
#endif

@available (iOS 14, watchOS 7, macOS 10.16, tvOS 14, *)
public extension View {
	func notificationOverlay(_ appNotifications: AppNotifications) -> some View {
		return self.overlay(NotificationOverlay(appNotifications: appNotifications))
	}
}

/// Overlays a notification on top of the views
@available (iOS 14, watchOS 7, macOS 10.16, tvOS 14, *)
public struct NotificationOverlay: View {
	@ObservedObject var appNotifications: AppNotifications
	
	@State private var isExpanded: Bool = false
	@State private var translation = CGSize.zero
	
	let animation: Animation = .interpolatingSpring(mass: 0.5, stiffness: 45, damping: 45, initialVelocity: 15)
	
	private func expandGestureHandler() {
		guard let notification = appNotifications.notification else {
			return
		}
	
		if notification.expandedText != nil {
			UIImpactFeedbackGenerator(style: .light).impactOccurred()
			isExpanded.toggle()
			
			if notification.autodismisses {
				if isExpanded {
					appNotifications.cancelTimer()
				} else {
					appNotifications.instantiateTimer()
				}
			}
		}
	}
	
	private var yOffset: CGFloat {
		if translation.height > 0 {
			return translation.height * 0.075
		}
		
		return translation.height
	}
	
	private var notificationDragGesture: some Gesture {
		DragGesture()
			.onChanged { value in
				translation = value.translation
			}
			.onEnded { value in
				if value.translation.height < -20 {
					appNotifications.isPresented = false
				} else if value.translation.height > 20 {
					expandGestureHandler()
				}
				translation = CGSize.zero
			}
	}
	
	private var background: some View {
		Rectangle()
			.fill(appNotifications.notification?.backgroundColor.opacity(0.1) ?? Color.clear)
			.background(Color(UIColor.systemBackground))
	}
	
	@ViewBuilder private var notificationView: some View {
		if let notification = appNotifications.notification, appNotifications.isPresented {
			VStack(alignment: .leading, spacing: 5) {
				HStack {
					Image(systemName: notification.icon)
						.font(.system(size: 26, weight: .bold, design: .default))
						.foregroundColor(notification.primaryColor)
						.id(notification.icon)
					
					VStack(alignment: .leading, spacing: 2) {
						Text(LocalizedStringKey(notification.title))
							.font(.headline)
							.lineLimit(2)
							.foregroundColor(notification.primaryColor)
							.id(notification.title)
						
						Text(LocalizedStringKey(notification.subtitle))
							.font(.headline)
							.opacity(0.5)
							.lineLimit(3)
							.foregroundColor(notification.primaryColor)
							.id(notification.subtitle)
					}
					.padding(.horizontal, 5)
				}
				
				if let expandedText = notification.expandedText,
				   isExpanded {
					Text(LocalizedStringKey(expandedText))
						.font(.headline)
						.multilineTextAlignment(.leading)
						.lineLimit(nil)
						.foregroundColor(notification.primaryColor)
						.opacity(0.75)
						.padding(.top, 5)
						.onAppear {
							appNotifications.cancelTimer()
						}
						.onDisappear {
							if notification.autodismisses {
								appNotifications.instantiateTimer()
							}
						}
						.transition(.opacity)
						.id(expandedText)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)							// Full width
			.padding()																	// Background padding
			.background(background)														// Background
			.cornerRadius(16)															// Rounded corners
			.shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 0)			// Shadow
			.offset(x: 0, y: yOffset)													// Dragging offset
			.frame(maxWidth: 600)														// Max width
			.padding(.horizontal)														// Additional padding
			.padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)	// Top safe area padding 
		}
	}
	
	public var body: some View {
		VStack(spacing: 0) {
			notificationView
				.onTapGesture(perform: expandGestureHandler)										// Tap gesture handler
				.gesture(notificationDragGesture)													// Drag gesture
				.animation(animation)																// Spring animation
				.transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .top)))	// Transition
			
			Spacer()
		}
		.edgesIgnoringSafeArea(.top)	// Hides the view when notification isn't visible
	}
}
#endif

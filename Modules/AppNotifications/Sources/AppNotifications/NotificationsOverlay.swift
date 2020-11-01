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
				}
				translation = CGSize.zero
			}
	}
	
	@ViewBuilder var notificationContent: some View {
		if let notification = appNotifications.notification {
			VStack(alignment: .leading) {
				HStack {
					Image(systemName: notification.icon)
						.font(.system(size: 26, weight: .bold, design: .default))
						.id(notification.icon)
						.foregroundColor(notification.primaryColor)
					
					VStack(alignment: .leading) {
						Text(LocalizedStringKey(notification.title))
							.font(.headline)
							.lineLimit(2)
							.id(notification.title)
							.foregroundColor(notification.primaryColor)
						
						Text(LocalizedStringKey(notification.subtitle))
							.font(.headline)
							.opacity(0.5)
							.lineLimit(3)
							.id(notification.subtitle)
							.foregroundColor(notification.primaryColor)
					}
					.padding(.horizontal, 5)
					
					Spacer()
				}
				
				if let expandedText = notification.expandedText,
				   isExpanded {
					VStack {
						Text(LocalizedStringKey(expandedText))
							.font(.headline)
							.multilineTextAlignment(.leading)
							.lineLimit(nil)
							.foregroundColor(notification.primaryColor)
							.opacity(0.75)
					}
					.transition(.opacity)
					.padding(.top, 5)
					.onAppear {
						appNotifications.cancelTimer()
					}
					.onDisappear {
						if notification.autodismisses {
							appNotifications.instantiateTimer()
						}
					}
				}
			}
			.padding()
			.padding(.vertical, 5)
			.background(notification.backgroundColor)
			.background(Color(UIColor.systemBackground))
			.mask(RoundedRectangle(cornerRadius: 14, style: .circular))
			.gesture(notificationDragGesture)
			.onTapGesture {
				if notification.expandedText != nil {
					#if os(iOS)
					UIImpactFeedbackGenerator(style: .light).impactOccurred()
					#endif
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
			.shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 0)
			.offset(x: 0, y: appNotifications.isPresented ? yOffset : -200)
			.animation(.interpolatingSpring(mass: 0.5, stiffness: 45, damping: 45, initialVelocity: 15))
			.transition(.asymmetric(insertion: .move(edge: .top), removal: .offset(x: 0, y: -200)))
		}
	}
	
	public var body: some View {
		VStack {
			notificationContent
			
			Spacer()
		}
		.padding()
	}
}
#endif

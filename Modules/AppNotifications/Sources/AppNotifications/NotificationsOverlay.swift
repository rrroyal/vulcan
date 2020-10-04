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

/// Overlays a notification on top of the views
@available (iOS 14, watchOS 7, macOS 10.16, tvOS 14, *)
public struct NotificationOverlay: View {
	@Binding var notificationData: NotificationData?
	
	@State private var isPresented: Bool = false
	@State private var isExpanded: Bool = false
	@State private var timer: Timer.TimerPublisher = Timer.publish(every: 4, on: .main, in: .common)
	@State private var cancellable: Cancellable?
	@State private var translation = CGSize.zero
		
	private func instantiateTimer() {
		isPresented = true
		timer = Timer.publish(every: 4, on: .main, in: .common)
		cancellable = timer.connect()
		return
	}
	
	private func cancelTimer() {
		timer.connect().cancel()
		cancellable?.cancel()
		return
	}
	
	private var yOffset: CGFloat {
		if translation.height > 0 {
			return translation.height * 0.075
		}
		
		return translation.height
	}
	
	private var backgroundColor: Color {
		#if os(macOS)
		return Color(NSColor.windowBackgroundColor)
		#else
		return Color(UIColor.systemBackground)
		#endif
	}
	
	@ViewBuilder public var body: some View {
		if let notificationData: NotificationData = notificationData {
			VStack {
				VStack(alignment: .leading) {
					HStack {
						Image(systemName: notificationData.icon)
							.resizable()
							.scaledToFit()
							.frame(width: 28, height: 28, alignment: .center)
							.padding(.trailing, 5)
							.foregroundColor(notificationData.primaryColor)
							.id(notificationData.icon)
						
						VStack(alignment: .leading) {
							Text(LocalizedStringKey(notificationData.title))
								.font(.headline)
								.lineLimit(2)
								.foregroundColor(notificationData.primaryColor)
								.id(notificationData.title)
							Text(LocalizedStringKey(notificationData.subtitle))
								.font(.headline)
								.opacity(0.5)
								.lineLimit(3)
								.foregroundColor(notificationData.primaryColor)
								.id(notificationData.subtitle)
						}
						
						Spacer()
					}
					
					if (isExpanded && notificationData.expandedText != nil) {
						VStack {
							Text(LocalizedStringKey(notificationData.expandedText ?? ""))
								.font(.headline)
								.multilineTextAlignment(.leading)
								.lineLimit(nil)
								.foregroundColor(notificationData.primaryColor)
								.opacity(0.75)
						}
						.transition(.opacity)
						.padding(.top, 5)
						.onAppear {
							cancelTimer()
						}
						.onDisappear {
							if (notificationData.autodismisses) {
								instantiateTimer()
							}
						}
					}
				}
				.padding()
				.padding(.vertical, 5)
				.mask(RoundedRectangle(cornerRadius: 14, style: .circular))
				.background(notificationData.backgroundColor)
				.background(backgroundColor)
				.mask(RoundedRectangle(cornerRadius: 14, style: .circular))
				.shadow(color: notificationData.primaryColor == .primary ? Color.black.opacity(0.1) : notificationData.backgroundColor, radius: 20, x: 0, y: 0)
				.gesture(
					DragGesture()
						.onChanged { (value) in
							translation = value.translation
						}
						.onEnded { (value) in
							if (value.translation.height > 20) {
								// Expand
								if (notificationData.expandedText != nil) {
									#if os(iOS)
									UIImpactFeedbackGenerator(style: .light).impactOccurred()
									#endif
									isExpanded.toggle()
								}
							} else if (value.translation.height < -20) {
								// Hide
								if (notificationData.dismissable) {
									isPresented = false
								}
							}
							translation = CGSize.zero
						}
				)
				.onTapGesture {
					if (notificationData.expandedText != nil) {
						#if os(iOS)
						UIImpactFeedbackGenerator(style: .light).impactOccurred()
						#endif
						isExpanded.toggle()
						if (notificationData.autodismisses) {
							if (isExpanded) {
								cancelTimer()
							} else {
								instantiateTimer()
							}
						}
					}
				}
				.animation(.interpolatingSpring(mass: 0.5, stiffness: 45, damping: 45, initialVelocity: 15))
				
				Spacer()
			}
			.padding(.horizontal, 10)
			.padding(.top)
			.offset(x: 0, y: isPresented ? yOffset : -200)
			.opacity(isPresented ? 1 : 0)
			.animation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 10, initialVelocity: 0))
			.transition(.slide)
			.frame(maxWidth: 500)
			.onReceive(timer) { time in
				if (!isExpanded && notificationData.autodismisses) {
					isPresented = false
					cancelTimer()
				}
			}
			.onChange(of: notificationData) { notification in
				if notification.autodismisses {
					instantiateTimer()
				} else {
					cancelTimer()
				}
			}
		}
	}
}
#endif

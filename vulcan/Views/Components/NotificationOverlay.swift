//
//  NotificationOverlay.swift
//  vulcan
//
//  Created by royal on 30/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import Combine

enum NotificationStyle {
	case normal
	case information
	case warning
	case error
	case success
}

struct NotificationData {
	var autodismisses: Bool
	var dismissable: Bool
	var style: NotificationStyle
	var icon: String
	var title: String
	var subtitle: String
	var expandedText: String?
}

struct NotificationOverlay: View {
	@Binding var isPresented: Bool
	@Binding var notificationData: NotificationData?
	var publisher: PassthroughSubject<Bool, Never>
	
	@State var isExpanded: Bool = false
	@State var timer: Timer.TimerPublisher = Timer.publish(every: 5, on: .main, in: .common)
	@State private var cancellable: Cancellable?
	@State private var translation = CGSize.zero
	
	func instantiateTimer() {
		self.timer = Timer.publish(every: 5, on: .main, in: .common)
		self.cancellable = timer.connect()
		return
	}
	
	func cancelTimer() {
		self.timer.connect().cancel()
		self.cancellable?.cancel()
		return
	}
	
	private var yOffset: CGFloat {
		if (translation.height > 0 || !(notificationData?.dismissable ?? false)) {
			return translation.height * 0.1
		}
		
		return translation.height
	}
	
	var body: some View {
		var color: Color = .primary
		var backgroundColor: Color = Color(UIColor.tertiarySystemBackground)
		
		switch (self.notificationData?.style ?? .normal) {
			case .normal:
				color = .primary
				backgroundColor = Color(UIColor.tertiarySystemBackground)
				break
			case .information:
				color = .blue
				backgroundColor = Color.blue.opacity(0.1)
				break
			case .warning:
				color = .orange
				backgroundColor = Color.orange.opacity(0.1)
				break
			case .error:
				color = .red
				backgroundColor = Color.red.opacity(0.1)
				break
			case .success:
				color = .green
				backgroundColor = Color.green.opacity(0.1)
				break
		}
		
		return VStack {
			VStack(alignment: .leading) {
				HStack {
					Image(systemName: self.notificationData?.icon ?? "xmark")
						.resizable()
						.frame(width: 28, height: 28, alignment: .center)
						.padding(.trailing, 5)
						.foregroundColor(color)
						.id(self.notificationData?.icon ?? "xmark")
					
					VStack(alignment: .leading) {
						Text(LocalizedStringKey(self.notificationData?.title ?? ""))
							.font(.headline)
							.lineLimit(2)
							.foregroundColor(color)
							.id(self.notificationData?.title ?? "")
						Text(LocalizedStringKey(self.notificationData?.subtitle ?? ""))
							.font(.headline)
							.opacity(0.5)
							.lineLimit(3)
							.foregroundColor(color)
							.id(self.notificationData?.subtitle ?? "")
					}
					
					Spacer()
				}
				
				/* if (!isExpanded && self.notificationData.expandedText != nil) {
					HStack {
						Spacer()
						Image(systemName: "ellipsis")
							.foregroundColor(color)
							.opacity(0.1)
						Spacer()
					}
				} */
				
				if (isExpanded && self.notificationData?.expandedText != nil) {
					VStack {
						Text(LocalizedStringKey(self.notificationData?.expandedText ?? ""))
							.font(.headline)
							.multilineTextAlignment(.leading)
							.lineLimit(nil)
							.foregroundColor(color)
							.opacity(0.75)
					}
					.transition(.opacity)
					.padding(.top, 5)
					.onAppear {
						self.cancelTimer()
					}
					.onDisappear {
						if (self.notificationData?.autodismisses ?? false) {
							self.instantiateTimer()
						}
					}
				}
			}
			.padding()
			.padding(.vertical, 5)
			.mask(RoundedRectangle(cornerRadius: 14, style: .circular))
			.background(backgroundColor)
			.background(Color(UIColor.systemBackground))
			.mask(RoundedRectangle(cornerRadius: 14, style: .circular))
			.shadow(color: color == .primary ? Color.black.opacity(0.1) : backgroundColor, radius: 20, x: 0, y: 0)
			.gesture(
				DragGesture()
					.onChanged { (value) in
						self.translation = value.translation
				}
				.onEnded { (value) in
					if (value.translation.height > 20) {
						// Expand
						if (self.notificationData?.expandedText != nil) {
							generateHaptic(.light)
							self.isExpanded.toggle()
						}
					} else if (value.translation.height < -20) {
						// Hide
						if (self.notificationData?.dismissable ?? true) {
							self.isPresented = false
						}
					}
					self.translation = CGSize.zero
				}
			)
			.onTapGesture {
				if (self.notificationData?.expandedText != nil) {
					generateHaptic(.light)
					self.isExpanded.toggle()
				}
			}
			.animation(.interpolatingSpring(mass: 0.5, stiffness: 45, damping: 45, initialVelocity: 15))
			
			Spacer()
		}
		.padding(.horizontal, 10)
		.padding(.top)
		.offset(x: 0, y: (self.isPresented && self.notificationData != nil) ? self.yOffset : -175)
		// .opacity(self.notificationData != nil ? 1 : 0)
		.animation(.easeInOut(duration: 0.5))
		.transition(.opacity)
		.frame(maxWidth: 500)
		.onReceive(publisher) { data in
			self.isPresented = data
			if (data && (self.notificationData?.autodismisses ?? false)) {
				self.instantiateTimer()
			}
		}
		.onReceive(timer) { time in
			if (!self.isExpanded && self.notificationData?.autodismisses ?? true) {
				self.isPresented = false
				self.cancelTimer()
			}
		}
		.onAppear {
			if (self.notificationData == nil) {
				self.cancelTimer()
				self.isPresented = false
			}
						
			if (!(self.notificationData?.autodismisses ?? true)) {
				self.cancelTimer()
			} else {
				self.instantiateTimer()
			}
		}
		.onDisappear {
			self.cancelTimer()
		}
    }
}

/* struct NotificationOverlay_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			NotificationOverlay(isPresented: true, style: .normal)
				.previewDisplayName("Normal")
			NotificationOverlay(isPresented: true, style: .informal)
				.previewDisplayName("Informal")
			NotificationOverlay(isPresented: true, style: .warning)
				.previewDisplayName("Warning")
			NotificationOverlay(isPresented: true, style: .error)
				.previewDisplayName("Error")
		}
		.previewLayout(.sizeThatFits)
    }
} */

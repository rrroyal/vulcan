//
//  View+.swift
//  
//
//  Created by royal on 10/07/2020.
//

#if !WIDGET
import SwiftUI

@available (iOS 14, watchOS 7, macOS 10.16, tvOS 14, *)
public extension View {
	func notificationOverlay(_ notificationData: Binding<NotificationData?>) -> some View {
		return self.overlay(NotificationOverlay(notificationData: notificationData))
	}
}
#endif

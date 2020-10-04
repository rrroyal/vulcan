//
//  AppNotifications.swift
//  
//
//  Created by royal on 10/07/2020.
//

#if !WIDGET
import Foundation
import SwiftUI
import Combine

@available (iOS 14, macOS 10.16, watchOS 7, tvOS 14, *)
public final class AppNotifications: ObservableObject {
	public static let shared: AppNotifications = AppNotifications()
	
	@Published public var isPresented: Bool = false
	@Published public var notificationData: NotificationData? = nil
	
	public func sendNotification(_ notification: NotificationData) {
		self.notificationData = notification
	}
}

@available (iOS 14, macOS 10.16, watchOS 7, tvOS 14, *)
public struct NotificationData: Identifiable, Equatable {
	public enum NotificationStyle {
		case normal
		case information
		case warning
		case error
		case success
	}
	
	public init(id: UUID = UUID(), autodismisses: Bool, dismissable: Bool, style: NotificationStyle, icon: String, title: String, subtitle: String, expandedText: String? = nil) {
		self.id = id
		self.autodismisses = autodismisses
		self.dismissable = dismissable
		self.style = style
		self.icon = icon
		self.title = title
		self.subtitle = subtitle
		self.expandedText = expandedText
	}
	
	public var id: UUID = UUID()
	var autodismisses: Bool
	var dismissable: Bool
	var style: NotificationStyle
	var icon: String
	var title: String
	var subtitle: String
	var expandedText: String?
	
	var primaryColor: Color {
		switch (self.style) {
			case .normal:		return .primary
			case .information:	return .blue
			case .warning:		return .orange
			case .error:		return .red
			case .success:		return .green
		}
	}
	
	var backgroundColor: Color {
		switch (self.style) {
			#if os(macOS)
			case .normal:		return Color(NSColor.controlBackgroundColor)
			#else
			case .normal:		return Color(UIColor.tertiarySystemBackground)
			#endif
			case .information:	return Color.blue.opacity(0.1)
			case .warning:		return Color.orange.opacity(0.1)
			case .error:		return Color.red.opacity(0.1)
			case .success:		return Color.green.opacity(0.1)
		}
	}
}

public extension NotificationData {
	init(error: String) {
		self.init(autodismisses: true, dismissable: true, style: .error, icon: "exclamationmark.triangle.fill", title: "Error!", subtitle: error)
	}
}
#endif

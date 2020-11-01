//
//  Global.swift
//  bitty
//
//  Created by royal on 12/08/2020.
//


#if canImport(UIKit)
import UIKit
#endif

import CoreHaptics
import AudioToolbox

enum FeedbackStyle {
	case error
	case success
	case warning
	case light
	case medium
	case heavy
	case soft
	case rigid
	case selectionChanged
}

/// Generates a haptic feedback/vibration.
/// - Parameter style: Style of the feedback
func generateHaptic(_ style: FeedbackStyle) {
	#if !os(OSX)
	let hapticCapability = CHHapticEngine.capabilitiesForHardware()
	let supportsHaptics = hapticCapability.supportsHaptics
		
	if (supportsHaptics) {
		// Haptic Feedback
		switch style {
			case .error:	UINotificationFeedbackGenerator().notificationOccurred(.error); break
			case .success:	UINotificationFeedbackGenerator().notificationOccurred(.success); break
			case .warning:	UINotificationFeedbackGenerator().notificationOccurred(.warning); break
			case .light:	UIImpactFeedbackGenerator(style: .light).impactOccurred(); break
			case .medium:	UIImpactFeedbackGenerator(style: .medium).impactOccurred(); break
			case .heavy:	UIImpactFeedbackGenerator(style: .heavy).impactOccurred(); break
			case .soft: 	UIImpactFeedbackGenerator(style: .soft).impactOccurred(); break
			case .rigid:	UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); break
			case .selectionChanged:	UISelectionFeedbackGenerator().selectionChanged(); break
		}
	} else {
		// Older devices
		switch style {
			case .error:	AudioServicesPlaySystemSound(1521); break
			case .success:	break
			case .warning:	break
			case .light:	AudioServicesPlaySystemSound(1519); break
			case .medium:	break
			case .heavy:	AudioServicesPlaySystemSound(1520); break
			case .soft: 	break
			case .rigid:	break
			case .selectionChanged:	AudioServicesPlaySystemSound(1519); break
		}
	}
	#endif
}

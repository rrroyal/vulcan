//
//  UIWindow.swift
//  vulcan
//
//  Created by royal on 06/11/2020.
//

import UIKit.UIWindow

extension UIWindow {
	open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		super.motionEnded(motion, with: event)
		NotificationCenter.default.post(name: .DeviceDidShake, object: event)
	}
}

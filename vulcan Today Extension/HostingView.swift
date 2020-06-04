//
//  TodayViewController.swift
//  todayExtension
//
//  Created by royal on 29/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import UIKit
import SwiftUI
import NotificationCenter

class HostingView: UIViewController, NCWidgetProviding {
	let widgetView: WidgetView = WidgetView()
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		if (UserDefaults.user.isLoggedIn) {
			self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
		} else {
			self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
		}
    }
        
	@IBSegueAction func embedSwiftUIView(_ coder: NSCoder) -> UIViewController? {
		let hostingController: UIHostingController? = UIHostingController(coder: coder, rootView: widgetView.accentColor(Color.mainColor).onTapGesture {
			self.extensionContext?.open(URL(string: "vulcan://openExtension")!, completionHandler: { (success) in })
		})
		hostingController!.view.backgroundColor = .clear
		return hostingController
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.noData)
    }
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		switch activeDisplayMode {
			case .compact:
				preferredContentSize = maxSize
			case .expanded:
				var height: CGFloat = 0
				let today: Vulcan.Day? = DataModel.shared.schedule.first(where: { $0.events.first(where: { !$0.hasPassed }) != nil })
				today?.events.forEach { event in
					if (event.group == nil || event.actualGroup == UserDefaults.user.userGroup || UserDefaults.user.userGroup == 0) {
						height += 62.46
					}
				}
				
				preferredContentSize = CGSize(width: maxSize.width, height: min(height, maxSize.height))
			@unknown default:
				preconditionFailure("Unexpected value for activeDisplayMode.")
		}
	}
    
}

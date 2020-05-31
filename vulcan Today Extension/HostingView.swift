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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
	@IBSegueAction func embedSwiftUIView(_ coder: NSCoder) -> UIViewController? {
		let hostingController: UIHostingController? = UIHostingController(coder: coder, rootView: WidgetView())
		hostingController!.view.backgroundColor = .clear
		return hostingController
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}

//
//  HostingController.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 29/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<AnyView> {
    override var body: AnyView {
		return AnyView(ContentView().environmentObject((WKExtension.shared().delegate as! ExtensionDelegate).VulcanStore).accentColor(Color.mainColor))
    }
}

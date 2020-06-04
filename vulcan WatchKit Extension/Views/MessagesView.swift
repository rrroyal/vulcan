//
//  MessagesView.swift
//  vulcan WatchKit Extension
//
//  Created by royal on 04/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
	@EnvironmentObject var VulcanStore: VulcanAPIStore
	
	var body: some View {
		List {
			Text("Hello World!")
		}
		.navigationBarTitle(Text("Messages"))
	}
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

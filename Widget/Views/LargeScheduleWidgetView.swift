//
//  LargeScheduleWidgetView.swift
//  Widget
//
//  Created by royal on 03/09/2020.
//

import SwiftUI

struct LargeScheduleWidgetView: View {
	let entry: Provider.Entry
	
    var body: some View {
        MediumScheduleWidgetView(entry: entry)
    }
}

struct LargeScheduleWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LargeScheduleWidgetView(entry: .init(date: Date(), configuration: .init(), event: nil))
    }
}

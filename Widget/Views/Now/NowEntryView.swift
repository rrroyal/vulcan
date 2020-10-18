//
//  NowEntryView.swift
//  Widget
//
//  Created by Kacper on 18/10/2020.
//

import SwiftUI
import WidgetKit

struct NowEntryView: View {
	let entry: NowProvider.Entry
		
    var body: some View {
		EventView(event: entry.event)
    }
}

struct NowEntryView_Previews: PreviewProvider {
    static var previews: some View {
		NowEntryView(entry: .init(date: Date(), event: nil))
    }
}

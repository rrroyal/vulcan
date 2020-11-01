//
//  MessageDetailView.swift
//  WatchKit Extension
//
//  Created by royal on 19/09/2020.
//

import SwiftUI
import Vulcan

struct MessageDetailView: View {
	let message: Vulcan.Message
	
    var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				Text(message.title)
					.font(.headline)
				
				if let sender = message.sender {
					Text(sender)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
				
				Text(message.dateSent.formattedDateString(timeStyle: .short, dateStyle: .medium, context: .beginningOfSentence))
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
			.padding(.bottom, 5)
			
			Text(message.content)
		}
		.navigationTitle(message.title)
    }
}

/* struct MessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageDetailView()
    }
} */

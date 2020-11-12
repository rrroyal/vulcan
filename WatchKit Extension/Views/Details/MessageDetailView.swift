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
	
	public static let activityIdentifier: String = "\(Bundle.main.bundleIdentifier ?? "vulcan").MessageDetailActivity"
	
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
		/* .userActivity(Self.activityIdentifier) { activity in
			activity.isEligibleForSearch = false
			activity.isEligibleForPrediction = false
			activity.isEligibleForPublicIndexing = false
			activity.isEligibleForHandoff = true
			activity.title = message.title
			activity.persistentIdentifier = "MessageActivity"
			
			activity.userInfo = [
				"messageID": message.id
			]
		} */
    }
}

/* struct MessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageDetailView()
    }
} */

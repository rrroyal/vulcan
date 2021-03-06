//
//  MessagesView.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI
import Vulcan

struct MessagesView: View {
	@EnvironmentObject var vulcanStore: VulcanStore
	
    var body: some View {
		List {
			if (!vulcanStore.receivedMessages.isEmpty) {
				ForEach(vulcanStore.receivedMessages) { message in
					VStack {
						NavigationLink(destination: MessageDetailView(message: message)) {
							VStack(alignment: .leading) {
								Text(message.title)
									.font(.headline)
								
								if let sender = message.sender {
									Text(sender)
										.font(.subheadline)
										.foregroundColor(.secondary)
								}
							}
							.padding(.vertical)
							.opacity(message.hasBeenRead ? 0.5 : 1)
						}
					}
				}
			} else {
				Text("Nothing found")
					.multilineTextAlignment(.center)
					.opacity(0.3)
					.fullWidth()
			}
		}
		.listStyle(CarouselListStyle())
		.navigationTitle(Text("Messages"))
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

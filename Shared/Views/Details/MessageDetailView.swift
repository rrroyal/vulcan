//
//  MessageDetailView.swift
//  vulcan
//
//  Created by royal on 27/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

struct MessageDetailView: View {
	var message: Vulcan.Message

	@State private var isComposeSheetPresented: Bool = false
	
	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack(alignment: .leading) {
					if let messageSender = message.tag == .sent ? message.recipients?.map(\.name).joined(separator: ",") : message.sender {
						Text(messageSender)
							.font(.headline)
							.multilineTextAlignment(.leading)
							.lineLimit(nil)
					}
					
					Text(message.dateSent.formattedDateString(timeStyle: .medium, dateStyle: .full, context: .beginningOfSentence))
						.foregroundColor(.secondary)
						.multilineTextAlignment(.leading)
						.lineLimit(nil)
				}
				.padding(.bottom, 20)
				
				// Content
				HStack {
					Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
						.lineLimit(nil)
						.multilineTextAlignment(.leading)
					Spacer()
				}
				.contentShape(Rectangle())
				.onTapGesture {
					UIDevice.current.generateHaptic(.light)
					UIPasteboard.general.string = message.content
				}
				
				Spacer()
								
				// URLs
				if (!(message.content.urls ?? []).isEmpty) {
					VStack(alignment: .leading) {
						Text("Links")
							.font(.title)
							.bold()
						
						ForEach(message.content.urls ?? [], id: \.self) { url in
							LinkPreview(url: url)
								.frame(minHeight: 50, idealHeight: 70, maxHeight: 80)
								.id(url.absoluteString)
						}
					}
					.padding(.top)
				}
			}
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.padding(.horizontal)
			.padding(.bottom)
		}
		.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
		.navigationBarTitle(Text(message.title))
		.toolbar {
			// Reply button
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(action: {
					isComposeSheetPresented = true
				}) {
					Image(systemName: "arrowshape.turn.up.left")
						.navigationBarButton(edge: .trailing)
				}
			}
		}
		.sheet(isPresented: $isComposeSheetPresented) {
			ComposeMessageView(isPresented: $isComposeSheetPresented, message: .constant(message))
		}
		.onAppear {
			if (SettingsModel.shared.readMessageOnOpen && Vulcan.shared.currentUser != nil && !message.hasBeenRead) {
				Vulcan.shared.moveMessage(message: message, to: .read) { error in
					if let error = error {
						UIDevice.current.generateHaptic(.error)
						AppNotifications.shared.notification = .init(error: error.localizedDescription)
					}
				}
			}
		}
	}
}

struct MessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
		MessageDetailView(message: Vulcan.Message(id: 0, sender: nil, senderID: 0, recipients: nil, title: "title", content: "content", dateSentEpoch: 0, dateReadEpoch: nil, status: "", folder: "", read: nil))
    }
}

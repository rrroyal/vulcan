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
	
	var headerSection: some View {
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
		.fullWidth(alignment: .leading)
		.padding(.bottom, 10)
	}
	
	var contentSection: some View {
		Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
			.lineLimit(nil)
			.multilineTextAlignment(.leading)
			.contentShape(Rectangle())
			.onTapGesture {
				UIDevice.current.generateHaptic(.light)
				UIPasteboard.general.string = message.content
			}
			.padding(.bottom)
			.fullWidth(alignment: .leading)
	}
	
	@ViewBuilder
	var linksSection: some View {
		if let urls = message.content.urls, !urls.isEmpty {
			VStack {
				Section(header: Text("Links").sectionTitle().fullWidth(alignment: .leading)) {
					ForEach(urls, id: \.self) { url in
						LinkPreview(url: url)
							.id(url)
					}
				}
			}
			.padding(.bottom)
		}
	}
	
	var body: some View {
		ScrollView {
			LazyVStack {
				headerSection
				contentSection
				linksSection
			}
			.padding(.horizontal)
		}
		.navigationBarTitle(Text(message.title))
		.toolbar {
			// Reply button
			ToolbarItem(placement: .primaryAction) {
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

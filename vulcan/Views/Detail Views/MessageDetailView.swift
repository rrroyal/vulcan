//
//  MessageDetailView.swift
//  vulcan
//
//  Created by royal on 23/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct MessageDetailView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@State var message: Vulcan.Message
	@State var isComposeSheetPresented: Bool = false
	
    var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				VStack(alignment: .leading) {
					Text(message.sendersString.joined(separator: ", "))
						.font(.headline)
						.multilineTextAlignment(.leading)
						.lineLimit(nil)
					
					Text(message.sentDate.formattedString(format: "EEEE, d MMMM yyyy, HH:mm").capitalingFirstLetter())
						.foregroundColor(.secondary)
						.multilineTextAlignment(.leading)
						.lineLimit(nil)
				}
				.padding(.bottom, 22)
				
				// Content
				HStack {
					Text(message.content)
						.lineLimit(nil)
						.multilineTextAlignment(.leading)
					Spacer()
				}
				
				Spacer()
			}
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.padding(.horizontal)
			.padding(.bottom, 16)
			.onTapGesture {
				generateHaptic(.light)
				UIPasteboard.general.string = self.message.content
			}
		}
		.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
		.navigationBarTitle(Text(message.title))
		.navigationBarItems(trailing: Button(action: {
			self.isComposeSheetPresented = true
		}) {
			Image(systemName: "arrowshape.turn.up.left")
				.navigationBarButton(edge: .trailing)
		})
		.sheet(isPresented: $isComposeSheetPresented, content: { ComposeMessageView(isPresented: self.$isComposeSheetPresented, message: self.message).environmentObject(self.VulcanAPI) })
		.onAppear {
			if (!self.VulcanAPI.isLoggedIn || self.message.hasBeenRead) {
				return
			}
			
			if (UserDefaults.user.readMessageOnOpen) {
				self.VulcanAPI.moveMessage(messageID: self.message.id, tag: self.message.tag, folder: .read)
			}
		}
    }
}

/* struct MessageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MessageDetailView()
    }
} */

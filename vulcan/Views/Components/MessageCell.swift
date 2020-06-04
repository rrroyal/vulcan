//
//  MessageCell.swift
//  vulcan
//
//  Created by royal on 03/06/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct MessageCell: View {
	@State var message: Vulcan.Message
	
    var body: some View {
		VStack(alignment: .leading) {
			// Name Surname, Date
			HStack {
				Group {
					// Name Surname
					Text("\(message.senders.first?.name ?? "Unknown") \(message.senders.first?.surname ?? "Unknown")")
						.bold()
					// Date
					Text(message.sentDate.formattedString(format: "dd/MM/yyyy"))
				}
				.foregroundColor(.secondary)
				.font(.callout)
				.lineLimit(1)
				.allowsTightening(false)
			}
			.padding(.bottom, 4)
			
			// Title
			Text(message.title)
				.font(.headline)
				.multilineTextAlignment(.leading)
				.lineLimit(2)
				.allowsTightening(true)
				.truncationMode(.tail)
				.padding(.bottom, 4)
			
			// Content
			Text(message.content)
				.font(.subheadline)
				.multilineTextAlignment(.leading)
				.lineLimit(2)
				.truncationMode(.tail)
				.allowsTightening(true)
		}
		.padding(.vertical, 5)
		.opacity(message.hasBeenRead ? 0.25 : 1)
    }
}

/* struct MessageCell_Previews: PreviewProvider {
    static var previews: some View {
        MessageCell()
    }
} */

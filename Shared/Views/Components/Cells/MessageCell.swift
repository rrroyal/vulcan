//
//  MessageCell.swift
//  vulcan
//
//  Created by royal on 27/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

struct MessageCell: View {
	var message: Vulcan.Message
	@Binding var isComposeSheetPresented: Bool
	@Binding var messageToReply: Vulcan.Message?
	
	static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		formatter.locale = Locale.autoupdatingCurrent
		formatter.doesRelativeDateFormatting = true
		return formatter
	}()
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			// Name & Surname, Date
			HStack {
				Group {
					// Name & Surname
					if ((message.tag ?? .received) == .sent) {
						Text(message.recipientsString.joined(separator: ", "))
							.font(.headline)
					} else {
						Text(message.sender ?? "Unknown sender")
							.font(.headline)
					}
					
					Spacer()

					// Date
					// Text(message.dateSent.formattedDateString(timeStyle: .short, dateStyle: .medium))
					Text(message.dateSent, formatter: Self.dateFormatter)
						.multilineTextAlignment(.trailing)
						.font(.callout)
						.foregroundColor(Color(UIColor.gray))
				}
				.lineLimit(1)
			}
			
			// Title
			Text(message.title)
				.font(.body)
				.multilineTextAlignment(.leading)
				.lineLimit(2)
				.allowsTightening(true)
				.truncationMode(.tail)
			
			// Content
			Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
				.font(.callout)
				.multilineTextAlignment(.leading)
				.lineLimit(2)
				.truncationMode(.tail)
				.allowsTightening(true)
				.foregroundColor(Color(UIColor.gray))
		}
		.padding(.vertical, 10)
		.opacity(message.hasBeenRead ? 0.5 : 1)
		.onDrag {
			var string: String = ""
			string += "Od: \(message.sender ?? "Unknown sender")\n"
			string += "Data: \(self.message.dateSent.formattedString(format: "yyyy-MM-dd HH:mm:ss"))\n\n"
			string += self.message.content
			return NSItemProvider(object: string.trimmingCharacters(in: .whitespacesAndNewlines) as NSString)
		}
		.contextMenu {
			// Reply
			Button(action: {
				generateHaptic(.light)
				messageToReply = message
				isComposeSheetPresented = true
			}) {
				Text("Reply")
				Spacer()
				Image(systemName: "arrowshape.turn.up.left")
			}
			
			// Mark as read - only visible if not read yet or message sender isn't us
			if (!message.hasBeenRead && message.tag != .sent) {
				Button(action: {
					generateHaptic(.light)
					Vulcan.shared.moveMessage(message: message, to: .read) { error in
						if let error = error {
							generateHaptic(.error)
							AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
						}
					}
				}) {
					Text("Mark as read")
					Spacer()
					Image(systemName: "envelope.open")
				}
			}
			
			// Copy
			Button(action: {
				var string: String = ""
				if let sender = message.sender {
					string += "Od: \(sender)\n"
				}
				string += "Data: \(message.dateSent.formattedString(format: "yyyy-MM-dd HH:mm:ss"))\n\n"
				string += message.content
				generateHaptic(.light)
				UIPasteboard.general.string = string.trimmingCharacters(in: .whitespacesAndNewlines)
			}) {
				Text("Copy")
				Spacer()
				Image(systemName: "doc.on.doc")
			}
			
			Divider()
			
			// Remove
			if (message.tag == .received || message.tag == .sent) {
				Button(action: {
					generateHaptic(.medium)
					Vulcan.shared.moveMessage(message: message, to: .deleted) { error in
						if let error = error {
							generateHaptic(.error)
							AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
						}
					}
				}) {
					Text("Delete")
					Spacer()
					Image(systemName: "trash")
				}
				.foregroundColor(Color.red)
				.accentColor(Color.red)
			}
		}
	}
}

/* struct MessageCell_Previews: PreviewProvider {
    static var previews: some View {
        MessageCell()
    }
} */

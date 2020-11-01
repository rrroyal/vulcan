//
//  ComposeMessageView.swift
//  vulcan
//
//  Created by royal on 27/06/2020.
//

import SwiftUI
import Vulcan

fileprivate struct MessageRecipientsListView: View {
	@Binding var isRecipientsSheetVisible: Bool
	@Binding var messageRecipients: [Vulcan.Recipient]
	
	@State private var searchFilter: String = ""
	@FetchRequest(entity: DictionaryEmployee.entity(), sortDescriptors: [NSSortDescriptor(key: "surname", ascending: true)]) var employees: FetchedResults<DictionaryEmployee>
	
	private func isRecipient(_ recipient: DictionaryEmployee) -> Bool {
		let code = Int(recipient.id)
		let recipients = self.messageRecipients.map(\.id)
		return recipients.contains(code)
	}

	var body: some View {
		NavigationView {
			List {
				Section {
					TextField("Search", text: $searchFilter)
						.labelsHidden()
				}
				
				ForEach(searchFilter.isEmpty ? Array(employees) : employees.filter({ ($0.name ?? "").lowercased().contains(searchFilter.lowercased()) || ($0.surname ?? "").lowercased().contains(searchFilter.lowercased()) || ($0.code ?? "").lowercased().contains(searchFilter.lowercased()) })) { employee in
					if let employeeSurname = employee.surname,
					   let employeeName = employee.name,
					   let employeeCode = employee.code {
						HStack {
							Text("\(employeeSurname) \(employeeName) (\(employeeCode))".trimmingCharacters(in: .whitespacesAndNewlines))
							Spacer()
							Image(systemName: "checkmark")
								.opacity(isRecipient(employee) ? 1 : 0)
								.transition(.opacity)
								.animation(.easeInOut(duration: 0.1))
								.foregroundColor(.accentColor)
						}
						.contentShape(Rectangle())
						.onTapGesture {
							generateHaptic(.selectionChanged)
							
							if (isRecipient(employee)) {
								guard let recipientsIndex = messageRecipients.map(\.id).firstIndex(of: Int(employee.id)) else {
									return
								}
								
								messageRecipients.remove(at: recipientsIndex)
								return
							}
							
							let recipient = Vulcan.Recipient(id: Int(employee.id), name: "\(employee.surname ?? "Unknown employee") \(employee.name ?? "") (\(employee.code ?? ""))")
							messageRecipients.append(recipient)
						}
					}
				}
			}
			.listStyle(InsetGroupedListStyle())
			.navigationTitle(Text("Recipients"))
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(action: {
						isRecipientsSheetVisible = false
					}) {
						Text("Done")
					}
				}
			}
		}
	}
}

struct ComposeMessageView: View {
	@Binding var isPresented: Bool
	@Binding var message: Vulcan.Message?
	
	@State private var loading: Bool = false
	@State private var isRecipientsSheetVisible: Bool = false
	@State private var messageTitle: String = ""
	@State private var messageContent: String = ""
	@State private var messageRecipients: [Vulcan.Recipient] = []
		
	private var messageRecipientsString: [String] {
		self.messageRecipients
			.map(\.name)
	}
	
	/// Sends the message.
	private func sendMessage() {
		let title: String = messageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
		let content: String = messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if (title.isEmpty || content.isEmpty || messageRecipients.isEmpty) {
			return
		}
		
		loading = true
		generateHaptic(.light)
		
		Vulcan.shared.sendMessage(to: messageRecipients, title: messageTitle, content: messageContent) { error in
			loading = false
			
			if error == nil {
				generateHaptic(.success)
				isPresented = false
			} else {
				generateHaptic(.error)
			}
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			// Title and `send` button
			HStack {
				TextField("Title", text: $messageTitle)
					.font(.title)
					.allowsTightening(true)
					.minimumScaleFactor(0.75)
				
				Spacer()
				
				Button(action: sendMessage) {
					Image(systemName: "paperplane.fill")
						.navigationBarButton(edge: .trailing)
				}
				.disabled(messageTitle.isEmpty || messageContent.isEmpty || messageRecipients.isEmpty || loading)
			}
			
			// Recipients
			HStack {
				Image(systemName: "person.crop.circle")
				
				if (messageRecipientsString.isEmpty) {
					Text("Choose a recipient...")
				} else {
					Text(messageRecipientsString.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines))
				}
				
				Spacer()
			}
			.padding(.trailing)
			.padding(.vertical, 5)
			.contentShape(Rectangle())
			.foregroundColor(Color.accentColor)
			.onTapGesture {
				isRecipientsSheetVisible.toggle()
			}
			.onLongPressGesture {
				generateHaptic(.selectionChanged)
				messageRecipients.removeAll()
			}
			
			// Message content
			TextEditor(text: $messageContent)
				.lineLimit(nil)
				.multilineTextAlignment(.leading)
			
			Spacer()
		}
		.padding()
		.contentShape(Rectangle())
		.sheet(isPresented: $isRecipientsSheetVisible) {
			MessageRecipientsListView(isRecipientsSheetVisible: $isRecipientsSheetVisible, messageRecipients: $messageRecipients)
		}
		.loadingOverlay(loading)
		.allowsHitTesting(!loading)
		.onAppear {
			// Message reply setup
			if let message: Vulcan.Message = message {
				messageTitle = "RE: \(message.title)".trimmingCharacters(in: .whitespacesAndNewlines)
				
				// Why the fuck is `senderID` different than `DictionaryEmployee.id`?
				switch message.tag {
					case .received, .deleted, .none:
						messageRecipients = [Vulcan.Recipient(id: message.senderID, name: message.sender ?? "")]
					case .sent:
						messageRecipients = message.recipients ?? []
				}
								
				messageContent += "\n"
				if let sender = message.sender {
					messageContent += "\nOd: \(sender)"
				}
				messageContent += "\nData: \(message.dateSent.formattedString(format: "yyyy-MM-dd HH:mm:ss"))"
				messageContent += "\n\n\(message.content.trimmingCharacters(in: .whitespacesAndNewlines))"
			}
		}
	}
}

/* struct ComposeMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeMessageView()
    }
} */

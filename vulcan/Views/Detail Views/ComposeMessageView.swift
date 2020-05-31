//
//  ComposeMessageView.swift
//  vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ComposeMessageView: View {
	@Binding var isPresented: Bool
	var message: Vulcan.Message?
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	
	@State var loading: Bool = false
	@State var actionSheetButtons: [ActionSheet.Button] = []
	@State var isRecipientsSheetVisible: Bool = false
	@State var messageTitle: String = ""
	@State var messageContent: String = ""
	@State var messageRecipients: [Vulcan.Teacher] = []
	@State var messageRecipientsString: [String] = []
	
	func sendMessage() {
		let title: String = self.messageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
		let content: String = self.messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if (title.isEmpty || content.isEmpty || self.messageRecipients.count == 0) {
			return
		}
		
		self.loading = true
		generateHaptic(.light)
		UIApplication.shared.endEditing()
		
		self.VulcanAPI.sendMessage(recipients: self.messageRecipients, messageTitle: self.messageTitle, messageContent: self.messageContent) { success, error in
			self.loading = false
			
			if (success) {
				generateHaptic(.success)
				self.isPresented = false
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
				
				Button(action: {
					self.sendMessage()
				}) {
					Image(systemName: "paperplane.fill")
						.navigationBarButton(edge: .trailing)
				}
				.disabled(self.messageTitle.isEmpty || self.messageContent.isEmpty || self.messageRecipients.count == 0 || self.loading)
			}
			
			HStack {
				Image(systemName: "person.crop.circle")
				Text(self.messageRecipientsString.count == 0 ? LocalizedStringKey("Choose a recipient...") : LocalizedStringKey(self.messageRecipientsString.joined(separator: ", ")))
				Spacer()
			}
			.padding(.trailing)
			.padding(.vertical, 5)
			.contentShape(Rectangle())
			.foregroundColor(Color.mainColor)
			.onTapGesture {
				self.isRecipientsSheetVisible.toggle()
			}
			.onLongPressGesture {
				generateHaptic(.selectionChanged)
				self.messageRecipients.removeAll()
				self.messageRecipientsString.removeAll()
			}
			
			TextField("Message content...", text: $messageContent)
				.lineLimit(nil)
				.multilineTextAlignment(.leading)
			
			Spacer()
		}
		.padding()
		.contentShape(Rectangle())
		.modifier(AdaptsToSoftwareKeyboard())
		.onTapGesture {
			UIApplication.shared.endEditing()
		}
		.sheet(isPresented: $isRecipientsSheetVisible) {
			List(self.VulcanAPI.teachers) { teacher in
				HStack {
					Text("\(teacher.surname) \(teacher.name) (\(teacher.code))".trimmingCharacters(in: .whitespacesAndNewlines))
					Spacer()
					Image(systemName: "checkmark")
						.opacity(self.messageRecipients.contains(teacher) ? 1 : 0)
						.transition(.opacity)
						.animation(.easeInOut(duration: 0.1))
				}
				.contentShape(Rectangle())
				.onTapGesture {
					generateHaptic(.selectionChanged)
					
					if (self.messageRecipients.contains(teacher)) {
						guard let recipientsIndex = self.messageRecipients.firstIndex(of: teacher) else {
							return
						}
						guard let recipientsStringIndex = self.messageRecipientsString.firstIndex(of: "\(teacher.name) \(teacher.surname)") else {
							return
						}
						
						self.messageRecipients.remove(at: recipientsIndex)
						self.messageRecipientsString.remove(at: recipientsStringIndex)
						return
					}
					
					self.messageRecipients.append(teacher)
					self.messageRecipientsString.append("\(teacher.name) \(teacher.surname)")
				}
			}
			.listStyle(GroupedListStyle())
			.environment(\.horizontalSizeClass, .regular)
		}
		/* .navigationBarTitle(Text(self.messageTitle.isEmpty ? "New message" : self.messageTitle))
		.navigationBarItems(trailing: Button(action: {
				self.sendMessage()
			}) {
				Image(systemName: "paperplane.fill")
					.navigationBarButton(edge: .trailing)
			}
			.disabled(self.messageTitle.isEmpty || self.messageContent.isEmpty || self.messageRecipients.count == 0 || self.loading)
		) */
		.loadingOverlay(self.loading)
		.allowsHitTesting(!self.loading)
		.onAppear {
			// Message reply setup
			if (self.message != nil) {
				self.messageTitle = "RE: \(self.message?.title ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
				self.messageRecipients = (self.message?.senders ?? []) as [Vulcan.Teacher]
				self.messageRecipientsString = self.message?.sendersString ?? []
				
				self.messageContent += "\n\nOd: \(self.message?.sendersString.joined(separator: ", ") ?? "")"
				self.messageContent += "\nData: \(self.message?.sentDate.formattedString(format: "yyyy-MM-dd HH:mm:ss") ?? "")"
				self.messageContent += "\n\n\(self.message?.content ?? "")"
				self.messageContent = self.messageContent.trimmingCharacters(in: .whitespacesAndNewlines)
			}
		}
    }
}

/* struct ComposeMessageView_Previews: PreviewProvider {
    static var previews: some View {
		ComposeMessageView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
    }
} */

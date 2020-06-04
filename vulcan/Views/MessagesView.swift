//
//  MessagesView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// List view, containing (and allowing sending) messages
struct MessagesView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	@State var isActionSheetPresented: Bool = false
	@State var isFilterSheetPresented: Bool = false
	@State var isComposeSheetPresented: Bool = false
	@State var messageToReply: Vulcan.Message?
	@State var messageTag: Vulcan.MessageTag = .received
	@State var monthOffset: Int = 0
	@State var messagesFilter: Vulcan.Teacher?
	@State var messages: [Vulcan.Message] = []
	
	@State var previousMonthButtonText: LocalizedStringKey = "PREVIOUS_MONTH"
	@State var nextMonthButtonText: LocalizedStringKey = "NEXT_MONTH"
	@State var tagStringKey: LocalizedStringKey = "Received"
	
	var buttonOrIndicator: some View {
		HStack {
			Group {
				if (self.VulcanAPI.dataState.messages.loading) {
					ActivityIndicator(isAnimating: self.$VulcanAPI.dataState.messages.loading, style: .medium)
				} else {
					Button(action: {
						self.isActionSheetPresented.toggle()
					}) {
						Image(systemName: "folder")
							.navigationBarButton(edge: .leading)
					}
				}
			}
			.actionSheet(isPresented: $isActionSheetPresented) {
				ActionSheet(title: Text("MESSAGES_FOLDER_TITLE"), buttons: [
					.default(Text("Received")) {
						self.messageTag = .received
						generateHaptic(.light)
						let month: Date = Calendar.current.date(byAdding: .month, value: self.monthOffset, to: Date()) ?? Date()
						withAnimation {
							self.VulcanAPI.getMessages(tag: self.messageTag, persistentData: self.monthOffset == 0, startDate: month.startOfMonth, endDate: month.endOfMonth) { success, error in
								if (error != nil) {
									generateHaptic(.error)
								}
								
								self.messages = self.VulcanAPI.messages.received
								self.tagStringKey = "Received"
							}
						}
					},
					.default(Text("Sent")) {
						self.messageTag = .sent
						generateHaptic(.light)
						let month: Date = Calendar.current.date(byAdding: .month, value: self.monthOffset, to: Date()) ?? Date()
						withAnimation {
							self.VulcanAPI.getMessages(tag: self.messageTag, persistentData: self.monthOffset == 0, startDate: month.startOfMonth, endDate: month.endOfMonth) { success, error in
								if (error != nil) {
									generateHaptic(.error)
								}
								
								self.messages = self.VulcanAPI.messages.sent
								self.tagStringKey = "Sent"
							}
						}
					},
					.default(Text("Deleted")) {
						self.messageTag = .deleted
						generateHaptic(.light)
						let month: Date = Calendar.current.date(byAdding: .month, value: self.monthOffset, to: Date()) ?? Date()
						withAnimation {
							self.VulcanAPI.getMessages(tag: self.messageTag, persistentData: self.monthOffset == 0, startDate: month.startOfMonth, endDate: month.endOfMonth) { success, error in
								if (error != nil) {
									generateHaptic(.error)
								}
								
								self.messages = self.VulcanAPI.messages.deleted
								self.tagStringKey = "Deleted"
							}
						}
					},
					.cancel()
				])
			}
			Button(action: {
				self.isFilterSheetPresented.toggle()
			}) {
				Image(systemName: "line.horizontal.3.decrease")
					.navigationBarButton(edge: .leading)
			}
			.actionSheet(isPresented: $isFilterSheetPresented) {
				var options: [ActionSheet.Button] = [.default(Text("All"), action: { self.messagesFilter = nil })]
				self.VulcanAPI.teachers.uniques.forEach { teacher in
					options.append(.default(Text("\(teacher.surname) \(teacher.name) (\(teacher.code))"), action: {
						self.messagesFilter = teacher
					}))
				}
				options.append(.cancel())
				
				return ActionSheet(title: Text("Filter"), buttons: options)
			}
		}
	}
	
	private func changeMonth(next: Bool = true, reset: Bool = false) {
		generateHaptic(.light)
		
		self.previousMonthButtonText = "LOADING"
		self.nextMonthButtonText = "LOADING"
		
		if (reset) {
			self.monthOffset = 0
		} else {
			self.monthOffset += next ? 1 : -1
		}
		
		let month: Date = Calendar.current.date(byAdding: .month, value: self.monthOffset, to: Date()) ?? Date()
		self.VulcanAPI.getMessages(tag: self.messageTag, persistentData: reset, startDate: month.startOfMonth, endDate: month.endOfMonth) { success, error in
			if (error != nil) {
				generateHaptic(.error)
			}
			
			switch (self.messageTag) {
				case .received:	self.messages = self.VulcanAPI.messages.received; break
				case .sent:		self.messages = self.VulcanAPI.messages.sent; break
				case .deleted:	self.messages = self.VulcanAPI.messages.deleted; break
			}
						
			if (!success) {
				self.monthOffset -= next ? 1 : -1
			}
			
			var previousMonthText: LocalizedStringKey = "PREVIOUS_MONTH : \((Calendar.current.date(byAdding: .month, value: self.monthOffset - 1, to: Date()) ?? Date()).startOfMonth.formattedString(format: "MMM yyyy"))"
			var nextMonthText: LocalizedStringKey = "NEXT_MONTH : \((Calendar.current.date(byAdding: .month, value: self.monthOffset + 1, to: Date()) ?? Date()).startOfMonth.formattedString(format: "MMM yyyy"))"
			
			if (self.monthOffset == 1) {
				previousMonthText = "CURRENT_MONTH : \(Date().formattedString(format: "MMM yyyy"))"
			} else if (self.monthOffset == -1) {
				nextMonthText = "CURRENT_MONTH : \(Date().formattedString(format: "MMM yyyy"))"
			}
			
			self.previousMonthButtonText = previousMonthText
			self.nextMonthButtonText = nextMonthText
		}
	}
	
	var previousMonthButton: some View {
		Button(action: {
			withAnimation {
				self.changeMonth(next: false)
			}
		}) {
			Text(self.previousMonthButtonText)
				.id("previousmonthbutton:\(self.monthOffset):\(self.VulcanAPI.dataState.messages)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
				.multilineTextAlignment(.center)
		}
	}
	
	var currentMonthButton: some View {
		Button(action: {
			withAnimation {
				self.changeMonth(reset: true)
			}
		}) {
			Text("CURRENT_MONTH : \(Date().formattedString(format: "MMM yyyy"))")
				.id("currentmonthbutton:\(self.monthOffset):\(self.VulcanAPI.dataState.messages)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
				.multilineTextAlignment(.center)
		}
	}
	
	var nextMonthButton: some View {
		Button(action: {
			withAnimation {
				self.changeMonth(next: true)
			}
		}) {
			Text(self.nextMonthButtonText)
				.id("nextmonthbutton:\(self.monthOffset):\(self.VulcanAPI.dataState.messages)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
				.multilineTextAlignment(.center)
		}
	}
	
	var body: some View {
		NavigationView {
			List {
				// Current/previous button
				Section {
					if (self.monthOffset > 1) {
						currentMonthButton
					}
					
					previousMonthButton
				}
				
				// Messages
				if (self.messagesFilter == nil ? self.messages.count == 0 : self.messages.filter({ $0.senders.contains(self.messagesFilter!) }).count == 0) {
					HStack {
						Spacer()
						Text("No messages")
						Spacer()
					}
				} else {
					ForEach(self.messagesFilter == nil ? self.messages : self.messages.filter({ $0.senders.contains(self.messagesFilter!) })) { message in
						NavigationLink(destination: MessageDetailView(message: message)) {
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
							.contextMenu {
								// Reply
								Button(action: {
									generateHaptic(.light)
									self.messageToReply = message
									self.isComposeSheetPresented = true
								}) {
									Text("Reply")
									Spacer()
									Image(systemName: "arrowshape.turn.up.left")
								}
								
								// Mark as read - only visible if not read yet or message sender isn't us
								if (!message.hasBeenRead && message.tag != .sent) {
									Button(action: {
										generateHaptic(.light)
										self.VulcanAPI.moveMessage(messageID: message.id, tag: message.tag, folder: .read) { success, error in
											if (error != nil) {
												generateHaptic(.error)
											}
											switch (self.messageTag) {
												case .received: self.messages = self.VulcanAPI.messages.received; break;
												case .sent: self.messages = self.VulcanAPI.messages.sent; break;
												case .deleted: self.messages = self.VulcanAPI.messages.deleted; break
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
									string += "Od: \(message.sendersString.joined(separator: ", "))\n"
									string += "Data: \(message.sentDate.formattedString(format: "yyyy-MM-dd HH:mm:ss"))\n\n"
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
								Button(action: {
									generateHaptic(.medium)
									self.VulcanAPI.moveMessage(messageID: message.id, tag: message.tag, folder: .deleted) { success, error in
										if (error != nil) {
											generateHaptic(.error)
										}
										switch (self.messageTag) {
											case .received: self.messages = self.VulcanAPI.messages.received; break;
											case .sent: self.messages = self.VulcanAPI.messages.sent; break;
											case .deleted: self.messages = self.VulcanAPI.messages.deleted; break
										}
									}
								}) {
									Text("Delete")
									Spacer()
									Image(systemName: "trash")
								}
								.foregroundColor(Color.red)
							}
							.onDrag {
								var string: String = ""
								string += "Od: \(message.sendersString.joined(separator: ", "))\n"
								string += "Data: \(message.sentDate.formattedString(format: "yyyy-MM-dd HH:mm:ss"))\n\n"
								string += message.content
								return NSItemProvider(object: string.trimmingCharacters(in: .whitespacesAndNewlines) as NSString)
							}
						}
					}
				}
				
				// Next/current month button
				Section {
					nextMonthButton
					
					if (self.monthOffset < -1) {
						currentMonthButton
					}
				}
			}
			.listStyle(GroupedListStyle())
			.environment(\.horizontalSizeClass, .regular)
			.navigationBarTitle(Text(self.tagStringKey))
			.navigationBarItems(
				leading: buttonOrIndicator,
				trailing: Button(action: {
					self.messageToReply = nil
					self.isComposeSheetPresented = true
				}) {
					Image(systemName: "square.and.pencil")
						.navigationBarButton(edge: .trailing)
				}
			)
			.onAppear {
				switch (self.messageTag) {
					case .received:	self.messages = self.VulcanAPI.messages.received; break
					case .sent:		self.messages = self.VulcanAPI.messages.sent; break
					case .deleted:	self.messages = self.VulcanAPI.messages.deleted; break
				}
			}
			
			Text("Nothing selected")
				.opacity(0.1)
		}
		// .allowsHitTesting(!self.VulcanAPI.dataState.messages.loading)
		// .loadingOverlay(self.VulcanAPI.dataState.messages.loading)
		.sheet(isPresented: $isComposeSheetPresented, content: { ComposeMessageView(isPresented: self.$isComposeSheetPresented, message: self.messageToReply).environmentObject(self.VulcanAPI).environmentObject(self.Settings) })
		.onAppear {
			self.previousMonthButtonText = "PREVIOUS_MONTH : \((Calendar.current.date(byAdding: .month, value: self.monthOffset - 1, to: Date()) ?? Date()).startOfMonth.formattedString(format: "MMM yyyy"))"
			self.nextMonthButtonText = "NEXT_MONTH : \((Calendar.current.date(byAdding: .month, value: self.monthOffset + 1, to: Date()) ?? Date()).startOfMonth.formattedString(format: "MMM yyyy"))"
			
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || !(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				return
			}
			
			if (!self.VulcanAPI.dataState.messages.fetched || self.VulcanAPI.dataState.messages.lastFetched ?? Date(timeIntervalSince1970: 0) < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				self.VulcanAPI.getMessages(
					tag: self.messageTag,
					startDate: Date().startOfMonth,
					endDate: Date().endOfMonth
				) { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
					
					switch (self.messageTag) {
						case .received:	self.messages = self.VulcanAPI.messages.received; break
						case .sent:		self.messages = self.VulcanAPI.messages.sent; break
						case .deleted:	self.messages = self.VulcanAPI.messages.deleted; break
					}
				}
			}
		}
	}
}

struct MessagesView_Previews: PreviewProvider {
	static var previews: some View {
		MessagesView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
	}
}

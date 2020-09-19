//
//  MessagesView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications

/// View containing the received, sent and deleted messages.
struct MessagesView: View {
	@EnvironmentObject var vulcan: Vulcan
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	
	@Binding var tag: Vulcan.MessageTag
	
	@State private var date: Date = Date()
	@State private var selection: Vulcan.Message?
	@State private var isComposeSheetPresented: Bool = false
	@State private var messageToReply: Vulcan.Message?
	
	/// Loads the data for the current month.
	private func fetch(timeIntervalSince1970: Double? = nil) {
		if (vulcan.dataState.messages[tag]?.loading ?? true) {
			return
		}
				
		let previousDate: Date = self.date
		let startDate: Date = self.date.startOfMonth
		let endDate: Date = self.date.endOfMonth
		
		vulcan.getMessages(tag: tag, isPersistent: (self.date.startOfMonth == Date().startOfMonth), from: startDate, to: endDate) { error in
			if let error = error {
				generateHaptic(.error)
				self.date = previousDate
				AppNotifications.shared.sendNotification(NotificationData(error: error.localizedDescription))
			}
		}
	}
	
	/// Removes the selected messages
	/// - Parameter indexSet: Indexes of the messages
	private func delete(indexSet: IndexSet) {
		generateHaptic(.medium)
		for index in indexSet {
			if (index <= vulcan.messages.combined.filter({ $0.tag == self.tag }).count) {
				let message: Vulcan.Message = vulcan.messages.combined.filter({ $0.tag == self.tag })[index]
				vulcan.moveMessage(messageID: message.id, tag: message.tag ?? tag, folder: .deleted) { error in
					if error != nil {
						generateHaptic(.error)
					}
				}
			}
		}
	}
	
	private func onAppear() {
		if (AppState.networking.monitor.currentPath.isExpensive || vulcan.currentUser == nil) {
			return
		}
		
		if (!(vulcan.dataState.messages[tag]?.fetched ?? false) || (vulcan.dataState.messages[tag]?.lastFetched ?? Date(timeIntervalSince1970: 0)) > (Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: Date()) ?? Date())) {
			fetch()
		}
	}
	
	/// Date picker
	private var datePicker: some View {
		DatePicker("Date", selection: $date, displayedComponents: .date)
			.datePickerStyle(CompactDatePickerStyle())
			.labelsHidden()
			.onChange(of: date.timeIntervalSince1970, perform: fetch)
	}
	
	/// Button used to change current messages folder.
	private var folderButton: some View {
		Menu(content: {
			Section {
				Button(action: {
					messageToReply = nil
					isComposeSheetPresented = true
				}) {
					Label("New", systemImage: "square.and.pencil")
				}
			}
			
			Section(header: Text("Folders")) {
				// Received
				Button(action: { tag = .received }) {
					Label("Received", systemImage: tag == .received ? "tray.fill" : "tray")
				}
				
				// Sent
				Button(action: { tag = .sent }) {
					Label("Sent", systemImage: tag == .sent ? "paperplane.fill" : "paperplane")
				}
				
				// Deleted
				Button(action: { tag = .deleted }) {
					Label("Deleted", systemImage: tag == .deleted ? "trash.fill" : "trash")
				}
			}
		}) {
			Image(systemName: "ellipsis.circle")
		}
	}
	
	/// Button used to refresh current messages.
	private var refreshButton: some View {
		RefreshButton(loading: (vulcan.dataState.messages[tag]?.loading ?? false), progressValue: vulcan.dataState.messages[tag]?.progress, iconName: "arrow.clockwise", edge: .trailing) {
			generateHaptic(.light)
			fetch()
		}
	}
	
	/// Button showing the `ComposeMessageView` sheet.
	private var newMessageButton: some View {
		Button(action: {
			messageToReply = nil
			isComposeSheetPresented = true
		}) {
			Image(systemName: "square.and.pencil")
				.navigationBarButton(edge: .trailing)
				// .frame(width: 22.5)
				// .padding(.vertical)
				// .font(.system(size: 20))
		}
	}
	
	private var content: some View {
		List {
			if ((vulcan.messages[tag] ?? []).count == 0) {
				Text("No messages found")
					.opacity(0.5)
					.multilineTextAlignment(.center)
					.fullWidth()
			} else {
				ForEach(vulcan.messages[tag] ?? []) { message in
					NavigationLink(destination: MessageDetailView(message: message)) {
						MessageCell(message: message, isComposeSheetPresented: $isComposeSheetPresented, messageToReply: $messageToReply)
					}
				}
				.onDelete(enabled: (tag == .received || tag == .sent), perform: delete)
			}
		}
		.listStyle(InsetGroupedListStyle())
		.onAppear { fetch() }
	}
	
	/// Sidebar ViewBuilder
	@ViewBuilder var body: some View {
		content
			.sheet(isPresented: $isComposeSheetPresented) {
				ComposeMessageView(isPresented: $isComposeSheetPresented, message: $messageToReply)
			}
			.toolbar {
				// Date picker
				ToolbarItemGroup(placement: .cancellationAction) {
					datePicker
					
					ProgressView(value: vulcan.dataState.messages[tag]?.progress)
						.transition(.opacity)
						.animation(.easeInOut)
						.opacity((vulcan.dataState.messages[tag]?.loading ?? false) ? 1 : 0)
				}
				
				// Menu + New message button
				#if os(iOS)
				ToolbarItem(placement: .primaryAction) {
					folderButton
						.navigationBarButton(edge: .trailing)
				}
				#endif
			}
			.navigationTitle(Text(LocalizedStringKey(tag.rawValue)))
	}
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
		MessagesView(tag: .constant(.received))
    }
}

//
//  MessagesView.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import Vulcan
import AppNotifications
import CoreSpotlight
import CoreServices

/// View containing the received, sent and deleted messages.
struct MessagesView: View {
	@EnvironmentObject var vulcan: Vulcan
	#if os(iOS)
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#endif
	
	@Binding var tag: Vulcan.MessageTag
	
	public static let activityIdentifier: String = "\(Bundle.main.bundleIdentifier ?? "vulcan").MessagesActivity"
	
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
				UIDevice.current.generateHaptic(.error)
				self.date = previousDate
				AppNotifications.shared.notification = .init(error: error.localizedDescription)
			}
		}
	}
	
	/// Removes the selected messages
	/// - Parameter indexSet: Indexes of the messages
	private func delete(indexSet: IndexSet) {
		UIDevice.current.generateHaptic(.medium)
		for index in indexSet {
			if (index <= vulcan.messages.combined.filter({ $0.tag == self.tag }).count) {
				let message: Vulcan.Message = vulcan.messages.combined.filter({ $0.tag == self.tag })[index]
				vulcan.moveMessage(message: message, to: .deleted) { error in
					if let error = error {
						UIDevice.current.generateHaptic(.error)
						AppNotifications.shared.notification = .init(error: error.localizedDescription)
					}
				}
			}
		}
	}
	
	private func onAppear() {
		if (AppState.shared.networkingMonitor.currentPath.isExpensive || vulcan.currentUser == nil) {
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
				.keyboardShortcut("n")
			}
			
			Section(header: Text("Folders")) {
				// Received
				Button(action: {
					tag = .received
					fetch()
				}) {
					Label("Received", systemImage: tag == .received ? "tray.fill" : "tray")
				}
				.keyboardShortcut("r")
				
				// Sent
				Button(action: {
					tag = .sent
					fetch()
				}) {
					Label("Sent", systemImage: tag == .sent ? "paperplane.fill" : "paperplane")
				}
				.keyboardShortcut("s")
				
				// Deleted
				Button(action: {
					tag = .deleted
					fetch()
				}) {
					Label("Deleted", systemImage: tag == .deleted ? "trash.fill" : "trash")
				}
				.keyboardShortcut("d")
			}
		}) {
			Image(systemName: "ellipsis.circle")
		}
	}
	
	/// Button used to refresh current messages.
	private var refreshButton: some View {
		RefreshButton(loading: (vulcan.dataState.messages[tag]?.loading ?? false), progressValue: vulcan.dataState.messages[tag]?.progress, iconName: "arrow.clockwise", edge: .trailing) {
			UIDevice.current.generateHaptic(.light)
			fetch()
		}
	}
	
	private var content: some View {
		List {
			if ((vulcan.messages[tag] ?? []).isEmpty) {
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
	}
	
	/// Sidebar ViewBuilder
	@ViewBuilder var body: some View {
		content
			.navigationTitle(Text(LocalizedStringKey(tag.rawValue)))
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
					
					/* if horizontalSizeClass == .compact {
						folderButton
							.navigationBarButton(edge: .trailing)
					} else {
						Button(action: {
							messageToReply = nil
							isComposeSheetPresented = true
						}) {
							Image(systemName: "square.and.pencil")
						}
						.navigationBarButton(edge: .trailing)
					} */
				}
				#endif
			}
			/* .userActivity(Self.activityIdentifier) { activity in
				activity.isEligibleForSearch = true
				activity.isEligibleForPrediction = true
				activity.isEligibleForPublicIndexing = true
				activity.isEligibleForHandoff = false
				activity.title = "Messages".localized
				activity.keywords = ["Messages".localized]
				activity.persistentIdentifier = "MessagesActivity"
				
				if let currentUser = Vulcan.shared.currentUser {
					activity.referrerURL = URL(string: "https://uonetplus-uzytkownik.vulcan.net.pl/\(currentUser.unitSymbol)")
					activity.webpageURL = activity.referrerURL
				}
				
				let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
				attributes.contentDescription = "See your received messages".localized
				
				activity.contentAttributeSet = attributes
			} */
			.onAppear {
				if AppState.shared.networkingMonitor.currentPath.isExpensive || AppState.shared.isLowPowerModeEnabled || vulcan.currentUser == nil {
					return
				}
				
				let nextFetch: Date = Calendar.autoupdatingCurrent.date(byAdding: .minute, value: 5, to: vulcan.dataState.messages[tag]?.lastFetched ?? Date(timeIntervalSince1970: 0)) ?? Date()
				if nextFetch <= Date() {
					fetch()
				}
			}
	}
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
		MessagesView(tag: .constant(.received))
    }
}

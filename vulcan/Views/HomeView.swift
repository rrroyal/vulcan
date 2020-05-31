//
//  HomeView.swift
//  vulcan
//
//  Created by royal on 06/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// Home view, containing dashboard for user
struct HomeView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	var divider: some View {
		VStack {
			RoundedRectangle(cornerRadius: 2, style: .circular).fill(Color.primary).opacity(0.03)
				.frame(minWidth: .zero, maxWidth: .infinity, minHeight: 2, maxHeight: 2)
		}
	}
	
	var loggedInView: some View {
		// Welcome message
		let hour: Int = Calendar.current.component(.hour, from: Date())
		var helloString: LocalizedStringKey = "HELLO : \(self.VulcanAPI.selectedUser?.Imie ?? "User")"
		
		if (hour >= 4 && hour < 13) {
			helloString = "GOOD_MORNING : \(self.VulcanAPI.selectedUser?.Imie ?? "User")"
		} else if (hour >= 13 && hour < 18) {
			helloString = "GOOD_AFTERNOON : \(self.VulcanAPI.selectedUser?.Imie ?? "User")"
		} else if ((hour >= 18 && hour < 24) || (hour >= 0 && hour < 4)) {
			helloString = "GOOD_EVENING : \(self.VulcanAPI.selectedUser?.Imie ?? "User")"
		}
		
		// Lessons
		let currentLesson: Vulcan.Event? = self.VulcanAPI.schedule.first(where: { $0.events.first(where: { $0.dateStarts < Date() && $0.dateEnds > Date() && $0.actualGroup == UserDefaults.user.userGroup }) != nil })?.events.first(where: { $0.dateStarts < Date() && $0.dateEnds > Date() && $0.actualGroup == UserDefaults.user.userGroup })
		let nextLesson: Vulcan.Event? = self.VulcanAPI.schedule.first(where: { $0.events.first(where: { !$0.hasPassed && $0.actualGroup == UserDefaults.user.userGroup }) != nil })?.events.first(where: { !$0.hasPassed && $0.actualGroup == UserDefaults.user.userGroup })
		
		// Tasks
		let newExams: [Vulcan.Task] = self.VulcanAPI.tasks.exams.filter({ $0.date > Date().startOfWeek ?? Date().startOfMonth && $0.date < Date().endOfWeek ?? Date().endOfMonth })
		let newHomework: [Vulcan.Task] = self.VulcanAPI.tasks.homework.filter({ $0.date > Date().startOfWeek ?? Date().startOfMonth && $0.date < Date().endOfWeek ?? Date().endOfMonth })
		
		// Messages
		let newMessages: [Vulcan.Message] = self.VulcanAPI.messages.received.filter({ !$0.hasBeenRead })
		
		return List {
			// General
			Section {
				VStack(alignment: .leading) {
					// Welcome message
					VStack(alignment: .leading) {
						Text(helloString)
							.font(.title)
							.bold()
							.allowsTightening(true)
							.minimumScaleFactor(0.5)
							.padding(.bottom, 2)
						
						Text("DATE_CURRENTLY : \(Date().formattedString(format: "EEEE, d MMMM yyyy, HH:mm"))")
							.font(.headline)
							.allowsTightening(true)
							.minimumScaleFactor(0.85)
					}
					
					Group {
						// Current lesson
						if (currentLesson != nil) {
							divider
							VStack(alignment: .leading, spacing: 0) {
								Text("Current lesson")
									.font(.headline)
									.opacity(0.25)
									.padding(.bottom, 2)
								Text("\(currentLesson!.subject.name) (\(currentLesson!.room))")
									.font(.headline)
									.padding(.bottom, 2)
								Text("\(currentLesson!.dateStarts.localizedTime) - \(currentLesson!.dateEnds.localizedTime) • \(currentLesson!.teacher.name) \(currentLesson!.teacher.surname)")
									.font(.callout)
									.foregroundColor(.secondary)
							}
						}
												
						// Next lesson
						if (nextLesson != nil) {
							divider
							VStack(alignment: .leading, spacing: 0) {
								Text("Next lesson")
									.font(.headline)
									.opacity(0.25)
									.padding(.bottom, 2)
								Text("\(nextLesson!.subject.name) (\(nextLesson!.room))")
									.font(.headline)
									.padding(.bottom, 2)
								Text("\(nextLesson!.dateStarts.formattedString(format: "EEEE").capitalingFirstLetter()), \(nextLesson!.dateStarts.localizedTime) - \(nextLesson!.dateEnds.localizedTime) • \(nextLesson!.teacher.name) \(nextLesson!.teacher.surname)")
									.font(.callout)
									.foregroundColor(.secondary)
							}
						}
					}
					.allowsTightening(true)
					.minimumScaleFactor(0.85)
				}
				.padding(.vertical, 5)
			}
			
			// Tasks - Exams
			if (newExams.count > 0) {
				Section(header: Text("Exams")) {
					ForEach(newExams) { task in
						VStack(alignment: .leading) {
							Text(task.description)
								.font(.headline)
								.padding(.bottom, 2)
							Text("\(task.subject.name) (\(task.date.formattedString(format: "EEEE, d MMMM yyyy")))")
								.font(.callout)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 5)
					}
				}
			}
			
			// Tasks - Homework
			if (newHomework.count > 0) {
				Section(header: Text("Homework")) {
					ForEach(newHomework) { task in
						VStack(alignment: .leading) {
							Text(task.description)
								.font(.headline)
								.padding(.bottom, 2)
							Text("\(task.subject.name) (\(task.date.formattedString(format: "EEEE, d MMMM yyyy")))")
								.font(.callout)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 5)
					}
				}
			}
			
			// Messages
			if (newMessages.count > 0) {
				Section(header: Text("New messages")) {
					ForEach(newMessages) { message in
						NavigationLink(destination: MessageDetailView(message: message)) {
							VStack(alignment: .leading) {
								Text(message.title.trimmingCharacters(in: .whitespacesAndNewlines))
									.font(.headline)
									.padding(.bottom, 2)
									.lineLimit(1)
									.allowsTightening(true)
									.minimumScaleFactor(0.85)
								Text(message.content.trimmingCharacters(in: .whitespacesAndNewlines))
									.font(.callout)
									.foregroundColor(.secondary)
									.lineLimit(2)
									.allowsTightening(true)
									.minimumScaleFactor(0.85)
							}
							.padding(.vertical, 5)
							.contextMenu {
								// Mark as read - only visible if not read yet or message sender isn't us
								if (!message.hasBeenRead && message.tag != .sent) {
									Button(action: {
										generateHaptic(.light)
										self.VulcanAPI.moveMessage(messageID: message.id, folder: .read) { success, error in
											if (error != nil) {
												generateHaptic(.error)
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
									self.VulcanAPI.moveMessage(messageID: message.id, folder: .deleted) { success, error in
										if (error != nil) {
											generateHaptic(.error)
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
			}
			
			// Details
			Section {
				NavigationLink(destination: UserDetailView().environmentObject(self.VulcanAPI).environmentObject(self.Settings).tag(ScreenPage.settings)) {
					Text("User details")
				}
			}
		}
		.listStyle(GroupedListStyle())
		.environment(\.horizontalSizeClass, .regular)
	}
	
    var body: some View {
		NavigationView {
			Group {
				if (self.VulcanAPI.isLoggedIn) {
					loggedInView
				} else {
					Text("Not logged in")
						.foregroundColor(.secondary)
				}
			}
			.navigationBarTitle(Text("Home"))
			.navigationBarItems(trailing: NavigationLink(destination: SettingsView().environmentObject(self.VulcanAPI).environmentObject(self.Settings).tag(ScreenPage.settings)) {
				Image(systemName: "gear")
					.navigationBarButton(edge: .trailing)
			})
		}
		.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
    }
}

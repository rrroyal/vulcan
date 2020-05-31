//
//  TasksView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// List view, containing homework and tests, one week at a time
struct TasksView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	@State var tasks: [Vulcan.Task] = []
	@State var taskTag: Vulcan.TaskTag = .exam
	@State var isActionSheetPresented: Bool = false
	@State var weekOffset: Int = 0
	
	@State var previousWeekButtonText: LocalizedStringKey = "PREVIOUS_WEEK"
	@State var nextWeekButtonText: LocalizedStringKey = "NEXT_WEEK"
	@State var tagStringKey: LocalizedStringKey = "Exams"
	
	private func changeWeek(next: Bool = true, reset: Bool = false) {
		generateHaptic(.light)
		
		self.previousWeekButtonText = "LOADING"
		self.nextWeekButtonText = "LOADING"
		
		if (reset) {
			self.weekOffset = 0
		} else {
			self.weekOffset += next ? 1 : -1
		}
		
		let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
		self.VulcanAPI.getTasks(tag: self.taskTag, startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
			if (error != nil) {
				generateHaptic(.error)
			}
			
			switch (self.taskTag) {
				case .exam:		self.tasks = self.VulcanAPI.tasks.exams; break
				case .homework:	self.tasks = self.VulcanAPI.tasks.homework; break
			}
			
			if (!success) {
				self.weekOffset -= next ? 1 : -1
			}
			
			var previousWeekText: LocalizedStringKey = "PREVIOUS_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset - 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			var nextWeekText: LocalizedStringKey = "NEXT_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset + 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			
			if (self.weekOffset == 1) {
				previousWeekText = "CURRENT_WEEK : \((Date().startOfWeek ?? Date()).formattedString(format: "dd MMMM yyyy"))"
			} else if (self.weekOffset == -1) {
				nextWeekText = "CURRENT_WEEK : \((Date().startOfWeek ?? Date()).formattedString(format: "dd MMMM yyyy"))"
			}
			
			self.previousWeekButtonText = previousWeekText
			self.nextWeekButtonText = nextWeekText
		}
	}
	
	var previousWeekButton: some View {
		Button(action: {
			withAnimation {
				self.changeWeek(next: false)
			}
		}) {
			Text(self.previousWeekButtonText)
				.tag("previousweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.tasks)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
		}
	}
	
	var currentWeekButton: some View {
		Button(action: {
			withAnimation {
				self.changeWeek(reset: true)
			}
		}) {
			Text("CURRENT_WEEK : \((Date().startOfWeek ?? Date()).formattedString(format: "dd MMMM yyyy"))")
				.tag("currentweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.tasks)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
		}
	}
	
	var nextWeekButton: some View {
		Button(action: {
			withAnimation {
				self.changeWeek(next: true)
			}
		}) {
			Text(self.nextWeekButtonText)
				.tag("nextweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.tasks)")
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.transition(.opacity)
		}
	}
	
	var body: some View {
		NavigationView {
			List {
				// Current/PREVIOUS_WEEK button
				Section {
					if (self.weekOffset > 1) {
						currentWeekButton
					}
					
					previousWeekButton
				}
				
				// Days
				if (self.tasks.count == 0) {
					HStack {
						Spacer()
						Text("No tasks")
						Spacer()
					}
				} else {
					ForEach(self.tasks) { exam in
						VStack(alignment: .leading) {
							Text(exam.description)
								.font(.headline)
								.multilineTextAlignment(.leading)
								.allowsTightening(true)
								.minimumScaleFactor(0.5)
								.lineLimit(4)
								.padding(.bottom, 2)
								
							Text("\(exam.subject.name) • \(exam.date.formattedString(format: "EEEE, d MMMM yyyy").capitalingFirstLetter())")
								.font(.callout)
								.foregroundColor(.secondary)
								.multilineTextAlignment(.leading)
								.allowsTightening(true)
								.minimumScaleFactor(0.5)
								.lineLimit(3)
						}
						.padding(.vertical, 5)
					}
				}
				
				// Next/current week button
				Section {
					nextWeekButton

					if (self.weekOffset < -1) {
						currentWeekButton
					}
				}
			}
			.listStyle(GroupedListStyle())
			.environment(\.horizontalSizeClass, .regular)
			.navigationBarTitle(Text(self.tagStringKey))
			.navigationBarItems(
				leading: Button(action: {
					self.isActionSheetPresented.toggle()
				}) {
					Image(systemName: "folder")
						.navigationBarButton(edge: .leading)
				}
				.actionSheet(isPresented: $isActionSheetPresented) {
					ActionSheet(title: Text("TASKS_FOLDER_TITLE"), buttons: [
						.default(Text("Exams")) {
							self.taskTag = .exam
							let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
							generateHaptic(.light)
							self.VulcanAPI.getTasks(tag: self.taskTag, startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
								if (error != nil) {
									generateHaptic(.error)
								}
								
								self.tasks = self.VulcanAPI.tasks.exams
								self.tagStringKey = "Exams"
							}
						},
						.default(Text("Homework")) {
							self.taskTag = .homework
							let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
							generateHaptic(.light)
							self.VulcanAPI.getTasks(tag: self.taskTag, startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
								if (error != nil) {
									generateHaptic(.error)
								}
								
								self.tasks = self.VulcanAPI.tasks.homework
								self.tagStringKey = "Homework"
							}
						},
						.cancel()
					])
				},
				trailing: Button(action: {
					generateHaptic(.light)
					let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
					self.VulcanAPI.getTasks(tag: self.taskTag, startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
						if (error != nil) {
							generateHaptic(.error)
						}
					}
				}) {
					Image(systemName: "arrow.clockwise")
						.navigationBarButton(edge: .trailing)
				}
			)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.allowsHitTesting(!self.VulcanAPI.dataState.tasks.loading)
		.loadingOverlay(self.VulcanAPI.dataState.tasks.loading)
		.onAppear {
			self.previousWeekButtonText = "PREVIOUS_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset - 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			self.nextWeekButtonText = "NEXT_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset + 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			
			switch (self.taskTag) {
				case .exam:		self.tasks = self.VulcanAPI.tasks.exams; break
				case .homework:	self.tasks = self.VulcanAPI.tasks.homework; break
			}
			
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || !(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				return
			}
			
			if (!self.VulcanAPI.dataState.tasks.fetched || self.VulcanAPI.dataState.tasks.lastFetched < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
				self.VulcanAPI.getTasks(tag: self.taskTag, startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
		}
	}
}

struct TasksView_Previews: PreviewProvider {
	static var previews: some View {
		TasksView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
	}
}

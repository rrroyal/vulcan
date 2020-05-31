//
//  ScheduleView.swift
//  vulcan
//
//  Created by royal on 05/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// List view, containing schedule, one week at a time
struct ScheduleView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	@State var weekOffset: Int = 0
	
	@State var previousWeekButtonText: LocalizedStringKey = "PREVIOUS_WEEK"
	@State var nextWeekButtonText: LocalizedStringKey = "NEXT_WEEK"
	
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
		
		self.VulcanAPI.getSchedule(startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
			if (error != nil) {
				generateHaptic(.error)
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
				.tag("previousweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.schedule)")
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
				.tag("currentweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.schedule)")
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
				.tag("nextweekbutton:\(self.weekOffset):\(self.VulcanAPI.dataState.schedule)")
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

				// Schedule
				if (self.VulcanAPI.schedule.count == 0) {
					HStack {
						Spacer()
						Text("No lessons")
						Spacer()
					}
				} else {
					ForEach(self.VulcanAPI.schedule) { item in
						Section(header: Text(item.id.formattedString(format: "EEEE, d MMMM").capitalingFirstLetter())) {
							ForEach(item.events) { event in
								if (event.group == nil || event.actualGroup == UserDefaults.user.userGroup || UserDefaults.user.userGroup == 0) {
									ScheduleEventCell(event: event)
								}
							}
						}
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
			.navigationBarTitle(Text("Schedule"))
			.navigationBarItems(trailing: Button(action: {
					generateHaptic(.light)
					let week: Date = Calendar.current.date(byAdding: .weekOfMonth, value: self.weekOffset, to: Date()) ?? Date()
					self.VulcanAPI.getSchedule(startDate: week.startOfWeek ?? Date(), endDate: week.endOfWeek ?? Date()) { success, error in
						if (error != nil) {
							generateHaptic(.error)
						}
					}
				}, label: {
					Image(systemName: "arrow.clockwise")
						.navigationBarButton(edge: .trailing)
				})
			)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.allowsHitTesting(!self.VulcanAPI.dataState.schedule.loading)
		.loadingOverlay(self.VulcanAPI.dataState.schedule.loading)
		.onAppear {
			self.previousWeekButtonText = "PREVIOUS_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset - 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			self.nextWeekButtonText = "NEXT_WEEK : \((Calendar.current.date(byAdding: .weekOfYear, value: self.weekOffset + 1, to: Date()) ?? Date()).startOfWeek?.formattedString(format: "dd MMMM yyyy") ?? "")"
			
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || !(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				return
			}
						
			if (!self.VulcanAPI.dataState.schedule.fetched || self.VulcanAPI.dataState.schedule.lastFetched < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				self.VulcanAPI.getSchedule(startDate: Date().startOfWeek ?? Date(), endDate: Date().endOfWeek ?? Date()) { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
		}
	}
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
    }
}

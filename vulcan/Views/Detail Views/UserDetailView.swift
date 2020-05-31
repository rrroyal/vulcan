//
//  UserDetailView.swift
//  vulcan
//
//  Created by royal on 26/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

/// View showing user's details (notes, final grades, etc.)
struct UserDetailView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	// MARK: - body
    var body: some View {
		Group {
			if (self.VulcanAPI.selectedUser != nil) {
				List {
					// MARK: - About
					Section(header: Text("About")) {
						// Name
						if (self.VulcanAPI.selectedUser?.Imie != nil && self.VulcanAPI.selectedUser?.Imie != "") {
							HStack {
								Text("Name")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.Imie ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Second name
						if (self.VulcanAPI.selectedUser?.Imie2 != nil && self.VulcanAPI.selectedUser?.Imie2 != "") {
							HStack {
								Text("Second name")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.Imie2 ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Surname
						if (self.VulcanAPI.selectedUser?.Nazwisko != nil && self.VulcanAPI.selectedUser?.Nazwisko != "") {
							HStack {
								Text("Surname")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.Nazwisko ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Nick
						if (self.VulcanAPI.selectedUser?.Pseudonim != nil && self.VulcanAPI.selectedUser?.Pseudonim != "") {
							HStack {
								Text("Nick")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.Pseudonim ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// ID
						if (self.VulcanAPI.selectedUser?.id != nil && self.VulcanAPI.selectedUser?.id != 0) {
							HStack {
								Text("ID")
									.bold()
								Spacer()
								Text("\(self.VulcanAPI.selectedUser?.id ?? 0)")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Login ID
						if (self.VulcanAPI.selectedUser?.LoginId != nil && self.VulcanAPI.selectedUser?.LoginId != 0) {
							HStack {
								Text("Login ID")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.LoginId != nil ? "\(String(describing: self.VulcanAPI.selectedUser?.LoginId))" : "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// User Login ID
						if (self.VulcanAPI.selectedUser?.UzytkownikLoginId != nil && self.VulcanAPI.selectedUser?.UzytkownikLoginId != 0) {
							HStack {
								Text("User Login ID")
									.bold()
								Spacer()
								Text("\(self.VulcanAPI.selectedUser?.UzytkownikLoginId ?? 0)")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Department Code
						if (self.VulcanAPI.selectedUser?.OddzialKod != nil && self.VulcanAPI.selectedUser?.OddzialKod != "") {
							HStack {
								Text("Department Code")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.OddzialKod ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Branch Name
						if (self.VulcanAPI.selectedUser?.JednostkaNazwa != nil && self.VulcanAPI.selectedUser?.JednostkaNazwa != "") {
							HStack {
								Text("Branch Name")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.JednostkaNazwa ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
						
						// Branch Name (short)
						if (self.VulcanAPI.selectedUser?.JednostkaSkrot != nil && self.VulcanAPI.selectedUser?.JednostkaSkrot != "") {
							HStack {
								Text("Branch Name (short)")
									.bold()
								Spacer()
								Text(self.VulcanAPI.selectedUser?.JednostkaSkrot ?? "")
									.lineLimit(nil)
									.allowsTightening(true)
									.minimumScaleFactor(0.5)
									.multilineTextAlignment(.trailing)
							}
						}
					}
					
					// MARK: - Anticipated grades
					Section(header: Text("Anticipated grades")) {
						if (self.VulcanAPI.endOfTermGrades.anticipated.count == 0) {
							HStack {
								Spacer()
								Text("Nothing found")
									.foregroundColor(.secondary)
								Spacer()
							}
						} else {
							ForEach(self.VulcanAPI.endOfTermGrades.anticipated, id: \.subject.id) { grade in
								HStack {
									Text(grade.subject.name)
										.bold()
										.lineLimit(2)
										.allowsTightening(true)
										.minimumScaleFactor(0.5)
										.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)") : Color.primary)
									Spacer()
									Text("\(grade.grade)")
										.bold()
										.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)") : Color.primary)
								}
								.padding(.vertical, 10)
								.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)").opacity(0.1) : nil)
							}
						}
					}
					.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
					.loadingOverlay(self.VulcanAPI.dataState.eotGrades.loading)
					
					// MARK: - Final grades
					Section(header: Text("Final grades")) {
						if (self.VulcanAPI.endOfTermGrades.final.count == 0) {
							HStack {
								Spacer()
								Text("Nothing found")
									.foregroundColor(.secondary)
								Spacer()
							}
						} else {
							ForEach(self.VulcanAPI.endOfTermGrades.final, id: \.subject.id) { grade in
								HStack {
									Text(grade.subject.name)
										.bold()
										.lineLimit(2)
										.allowsTightening(true)
										.minimumScaleFactor(0.5)
										.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)") : Color.primary)
									Spacer()
									Text("\(grade.grade)")
										.bold()
										.foregroundColor(UserDefaults.user.colorizeGrades ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)") : Color.primary)
								}
								.padding(.vertical, 10)
								.listRowBackground((UserDefaults.user.colorizeGrades && UserDefaults.user.colorizeGradeBackground) ? Color("ColorSchemes/\(UserDefaults.user.colorScheme)/\(grade.grade)").opacity(0.1) : nil)
							}
						}
					}
					.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
					.loadingOverlay(self.VulcanAPI.dataState.eotGrades.loading)
					
					// MARK: - Notes
					Section(header: Text("Notes")) {
						if (self.VulcanAPI.notes.count == 0) {
							HStack {
								Spacer()
								Text("Nothing found")
									.foregroundColor(.secondary)
								Spacer()
							}
						} else {
							ForEach(self.VulcanAPI.notes) { note in
								VStack(alignment: .leading) {
									Text(note.content)
										.font(.headline)
										.allowsTightening(true)
										.minimumScaleFactor(0.5)
										.lineLimit(nil)
										.padding(.bottom, 2)
									
									Text("\(note.teacher.name) \(note.teacher.surname): \(note.category.name) • \(note.date.formattedString(format: "dd/MM/yyyy"))")
										.foregroundColor(.secondary)
										.multilineTextAlignment(.leading)
										.allowsTightening(true)
										.minimumScaleFactor(0.5)
										.lineLimit(5)
								}
								.padding(.vertical, 5)
							}
						}
					}
					.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
					.loadingOverlay(self.VulcanAPI.dataState.notes.loading)
				}
				.listStyle(GroupedListStyle())
				.environment(\.horizontalSizeClass, .regular)
			} else {
				Text("Not logged in")
			}
		}
		.navigationBarTitle(Text("\(self.VulcanAPI.selectedUser?.Imie ?? "") \(self.VulcanAPI.selectedUser?.Nazwisko ?? "")"), displayMode: .automatic)
		.navigationBarItems(trailing: Button(action: {
			generateHaptic(.light)
			self.VulcanAPI.getEOTGrades() { success, error in
				if (error != nil) {
					generateHaptic(.error)
				}
			}
			self.VulcanAPI.getNotes() { success, error in
				if (error != nil) {
					generateHaptic(.error)
				}
			}
		}, label: {
			Image(systemName: "arrow.clockwise")
				.navigationBarButton(edge: .trailing)
		}))
		.onAppear {
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || !(UIApplication.shared.delegate as! AppDelegate).isReachable) {
				return
			}
			
			if (!self.VulcanAPI.dataState.eotGrades.fetched || self.VulcanAPI.dataState.eotGrades.lastFetched < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				self.VulcanAPI.getEOTGrades() { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
			
			if (!self.VulcanAPI.dataState.notes.fetched || self.VulcanAPI.dataState.notes.lastFetched < (Calendar.current.date(byAdding: .minute, value: -5, to: Date()) ?? Date())) {
				self.VulcanAPI.getNotes() { success, error in
					if (error != nil) {
						generateHaptic(.error)
					}
				}
			}
		}
    }
}

struct UserDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailView()
    }
}

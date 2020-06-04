//
//  UsersView.swift
//  vulcan
//
//  Created by royal on 04/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct UserListRow: View {
	var user: Vulcan.User
	@State var currentlySelected: Bool
	
	var body: some View {
		HStack {
			Image(systemName: "person.fill")
				.padding(.trailing, 5)
			
			Text("\(user.UzytkownikNazwa) (\(user.OddzialKod))")
			
			Spacer()
			
			if (currentlySelected) {
				Image(systemName: "checkmark")
			}
		}
		.accentColor(currentlySelected ? .mainColor : .primary)
	}
}

struct UsersView: View {
	@EnvironmentObject var VulcanAPI: VulcanAPIModel
	@EnvironmentObject var Settings: SettingsModel
	
	var body: some View {
		List(self.VulcanAPI.users) { user in
			Button(action: {
				generateHaptic(.light)
				self.VulcanAPI.setUser(user)
			}, label: {
				UserListRow(user: user, currentlySelected: user == self.VulcanAPI.selectedUser)
			})
		}
		.listStyle(GroupedListStyle())
		.environment(\.horizontalSizeClass, .regular)
		.navigationBarTitle(Text("Users"))
		.navigationBarItems(trailing: Button(action: {
			generateHaptic(.light)
			self.VulcanAPI.getUsers()
		}, label: {
			Image(systemName: "arrow.clockwise")
				.navigationBarButton(edge: .trailing)
			})
		)
		.loadingOverlay((self.VulcanAPI.users.count == 0) && UserDefaults.user.isLoggedIn)
		.onAppear {
			if (!self.VulcanAPI.isLoggedIn || !UserDefaults.user.isLoggedIn || self.VulcanAPI.users.count > 0) {
				return
			}
			
			self.VulcanAPI.getUsers()
		}
	}
}

struct UsersView_Previews: PreviewProvider {
    static var previews: some View {
        UsersView()
			.environmentObject(VulcanAPIModel())
			.environmentObject(SettingsModel())
    }
}

//
//  UsersView.swift
//  iOS
//
//  Created by royal on 27/06/2020.
//

import SwiftUI
import Vulcan

struct UsersView: View {
	@EnvironmentObject var vulcan: Vulcan
	
	private func refresh() {
		vulcan.getUsers() { error in
			if error != nil {
				generateHaptic(.error)
			}
		}
	}
	
	var body: some View {
		List(vulcan.users) { (user) in
			Button(action: {
				generateHaptic(.light)
				vulcan.setUser(user, force: true)
			}) {
				HStack {
					Image(systemName: "person.fill")
						.padding(.trailing, 5)
					
					Text("\(user.username) (\(user.unitCode))")
					
					Spacer()
					
					if user == vulcan.currentUser {
						Image(systemName: "checkmark")
							.foregroundColor(.accentColor)
					}
				}
			}
			.padding(.vertical, 10)
		}
		.listStyle(InsetGroupedListStyle())
		.navigationTitle(Text("Users"))
		/* .navigationBarItems(trailing: RefreshButton(loading: vulcan.dataState.users.loading, iconName: "arrow.clockwise", edge: .trailing) {
		generateHaptic(.light)
		refresh()
		}) */
		.toolbar {
			// Refresh button
			ToolbarItem(placement: .navigationBarTrailing) {
				RefreshButton(loading: vulcan.dataState.users.loading, iconName: "arrow.clockwise", edge: .trailing) {
					generateHaptic(.light)
					refresh()
				}
			}
		}
		.onAppear(perform: refresh)
	}
}

struct UsersView_Previews: PreviewProvider {
    static var previews: some View {
        UsersView()
    }
}

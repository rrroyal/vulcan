//
//  HomeCardCell.swift
//  WatchKit Extension
//
//  Created by royal on 04/09/2020.
//

import SwiftUI

struct HomeCardCell: View {
	let title: String
	let emoji: String
	
    var body: some View {
		VStack(alignment: .leading) {
			Text(emoji)
				.font(.title3)
				.padding(.bottom)
			
			Spacer()
			
			Text(LocalizedStringKey(title))
				.font(.headline)
		}
		.padding(.vertical)
		.frame(height: 100)
    }
}

struct HomeCardCell_Previews: PreviewProvider {
    static var previews: some View {
		HomeCardCell(title: "gang", emoji: "😶")
    }
}

//
//  ActivityIndicator.swift
//  vulcan
//
//  Created by royal on 08/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
	@Binding var isAnimating: Bool
	let style: UIActivityIndicatorView.Style
	
	func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
		return UIActivityIndicatorView(style: style)
	}
	
	func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
		isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
	}
}

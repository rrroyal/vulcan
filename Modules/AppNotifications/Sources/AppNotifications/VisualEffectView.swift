//
//  VisualEffectView.swift
//  
//
//  Created by Kacper on 06/11/2020.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
	let effect: UIVisualEffect
	
	func makeUIView(context: Context) -> some UIView {
		UIVisualEffectView(effect: effect)
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) { }
}

struct VisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
		VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    }
}

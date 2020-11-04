//
//  LinkPreview.swift
//  vulcan
//
//  Created by royal on 24/06/2020.
//

import SwiftUI
import LinkPresentation

/// LPLinkView wrapper
struct LinkPreview: UIViewRepresentable {
	var url: URL
	
	func makeUIView(context: Context) -> LPLinkView {
		let view = LPLinkView(url: url)
		let provider = LPMetadataProvider()
		
		provider.startFetchingMetadata(for: url) { metadata, error in
			if let metadata = metadata {
				DispatchQueue.main.async {
					view.metadata = metadata
					view.sizeToFit()
				}
			}
		}
		
		return view
	}
	
	func updateUIView(_ uiView: LPLinkView, context: UIViewRepresentableContext<LinkPreview>) {	}
}

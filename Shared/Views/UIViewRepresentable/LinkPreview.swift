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
	let url: URL
	
	let lpLinkView: LPLinkView
	
	public init(url: URL) {
		self.url = url
		self.lpLinkView = LPLinkView(url: url)
	}
	
	func makeUIView(context: Context) -> LPLinkView {
		let provider = LPMetadataProvider()
		
		provider.startFetchingMetadata(for: url) { metadata, error in
			if let metadata = metadata {
				DispatchQueue.main.async {
					self.lpLinkView.metadata = metadata
					self.lpLinkView.sizeToFit()
				}
			}
		}
		
		return lpLinkView
	}
	
	func updateUIView(_ uiView: LPLinkView, context: UIViewRepresentableContext<LinkPreview>) { }
}

//
//  MultilineTextField.swift
//  vulcan
//
//  Created by royal on 26/05/2020.
//  Copyright © 2020 shameful. All rights reserved.
//

import SwiftUI
import UIKit

fileprivate struct UITextViewWrapper: UIViewRepresentable {
	typealias UIViewType = UITextView
	
	@Binding var text: String
	@Binding var calculatedHeight: CGFloat
	var onCommit: (() -> Void)?
	var onEditingChanged: (() -> Void)?
	
	func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
		let textField = UITextView()
		
		textField.delegate = context.coordinator
		textField.isEditable = true
		textField.font = UIFont.preferredFont(forTextStyle: .body)
		textField.isSelectable = true
		textField.isUserInteractionEnabled = true
		textField.isScrollEnabled = true
		textField.backgroundColor = UIColor.clear
		textField.allowsEditingTextAttributes = false
		textField.autocapitalizationType = .sentences
		textField.returnKeyType = .default
		textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		textField.scrollsToTop = true
		
		return textField
	}
	
	func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
		if (uiView.text != self.text) {
			uiView.text = self.text
		}
		
		/* if uiView.window != nil, !uiView.isFirstResponder {
			uiView.becomeFirstResponder()
		} */
		
		UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
	}
	
	fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
		let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
		if (result.wrappedValue != newSize.height) {
			DispatchQueue.main.async {
				result.wrappedValue = newSize.height
			}
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(text: $text, height: $calculatedHeight, onCommit: onCommit)
	}
	
	final class Coordinator: NSObject, UITextViewDelegate {
		var text: Binding<String>
		var calculatedHeight: Binding<CGFloat>
		var onCommit: (() -> Void)?
		var onEditingChanged: (() -> Void)?
		
		init(text: Binding<String>, height: Binding<CGFloat>, onCommit: (() -> Void)? = nil, onEditingChanged: (() -> Void)? = nil) {
			self.text = text
			self.calculatedHeight = height
			self.onCommit = onCommit
			self.onEditingChanged = onEditingChanged
		}
		
		func textViewDidChange(_ uiView: UITextView) {
			text.wrappedValue = uiView.text
			UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
		}
		
		func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
			if let onCommit = self.onCommit, text == "\n\n" {
				textView.resignFirstResponder()
				onCommit()
				return false
			}
			return true
		}
	}
	
}

struct MultilineTextField: View {
	private var placeholder: String
	private var onCommit: (() -> Void)?
	private var onEditingChanged: (() -> Void)?
	
	@Binding private var text: String
	private var internalText: Binding<String> {
		Binding<String>(get: { self.text } ) {
			self.text = $0
			self.showingPlaceholder = $0.isEmpty
		}
	}
	
	@State private var dynamicHeight: CGFloat = 100
	@State private var showingPlaceholder = false
	
	init(_ placeholder: String = "", text: Binding<String>, onCommit: (() -> Void)? = nil, onEditingChanged: (() -> Void)? = nil) {
		self.placeholder = placeholder
		self.onCommit = onCommit
		self.onEditingChanged = onEditingChanged
		self._text = text
		self._showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
	}
	
	var body: some View {
		UITextViewWrapper(text: self.internalText, calculatedHeight: $dynamicHeight, onCommit: onCommit, onEditingChanged: onEditingChanged)
			.frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
			.background(placeholderView, alignment: .topLeading)
	}
	
	var placeholderView: some View {
		Group {
			if (text == "") {
				Text(placeholder).foregroundColor(.gray)
					.padding(.leading, 4)
					.padding(.top, 8)
			}
		}
	}
}

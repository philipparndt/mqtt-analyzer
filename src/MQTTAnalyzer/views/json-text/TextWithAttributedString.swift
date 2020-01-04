//
//  TextWithAttributedString.swift
//  SwiftUIAttributedStrings
//
//  Created by Gualtiero Frigerio on 20/08/2019.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//
import SwiftUI

class ViewWithLabel: UIView {
	fileprivate var label = UITextView()
	var height: CGFloat = 0
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		addSubview(label)
		
		label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		if traitCollection.userInterfaceStyle == .light {
			print("Light mode")
		} else {
			print("Dark mode")
		}
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if traitCollection.userInterfaceStyle == .light {
			print("Light mode")
		} else {
			print("Dark mode")
		}
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	func scale() {
		label.layoutSubviews()
		label.sizeToFit()
		height = label.frame.height
	}
}

struct TextWithAttributedString: UIViewRepresentable {
	var attributedString: NSAttributedString
	
	func makeUIView(context: Context) -> ViewWithLabel {
		return ViewWithLabel(frame: CGRect.zero)
	}
	
	func updateUIView(_ uiView: ViewWithLabel, context: UIViewRepresentableContext<TextWithAttributedString>) {
		uiView.label.attributedText = attributedString
	}
}

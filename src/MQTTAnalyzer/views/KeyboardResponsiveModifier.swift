//
//  KeyboardResponsiveModifier.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-03.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

class KeyboardResponsive {
	private var observer: [Any] = []

	func register(heightConsumer: @escaping (CGFloat) -> Void) {
		observer += [registerWillShowNotification(heightConsumer: heightConsumer)]
		observer += [registerWillHideNotification(heightConsumer: heightConsumer)]
	}
	
	func unregister() {
		for obs in observer {
			NotificationCenter.default.removeObserver(obs)
		}
	}
	
	deinit {
		unregister()
	}
	
	func registerWillShowNotification(heightConsumer: @escaping (CGFloat) -> Void) -> Any {
		return NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notif in
			let value = notif.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
			let height = value.height
			let bottomInset = UIApplication.shared.windows.first?.safeAreaInsets.bottom
			let offset = height - (bottomInset ?? 0)
			heightConsumer(offset)
		}
	}
	
	func registerWillHideNotification(heightConsumer: @escaping (CGFloat) -> Void) -> Any {
		return NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
			heightConsumer(0)
		}
	}
}

struct KeyboardResponsiveModifier: ViewModifier {
	@State private var offset: CGFloat = 0

	let responsive = KeyboardResponsive()
	
	func body(content: Content) -> some View {
		content
		  .padding(.bottom, offset)
		  .onAppear {
			self.responsive.register(heightConsumer: {
				self.offset = $0
			})
		}
		.onDisappear {
			self.responsive.unregister()
		}
	}
}

extension View {
  func keyboardResponsive() -> ModifiedContent<Self, KeyboardResponsiveModifier> {
	return modifier(KeyboardResponsiveModifier())
  }
}

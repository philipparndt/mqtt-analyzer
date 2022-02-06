//
//  TupleView+GetChildren.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-05.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

extension TupleView {
	var getViews: [AnyView] {
		makeArray(from: value)
	}
	
	private struct GenericView {
		let body: Any
		
		var anyView: AnyView? {
			AnyView(_fromValue: body)
		}
	}
	
	private func makeArray<Tuple>(from tuple: Tuple) -> [AnyView] {
		func convert(child: Mirror.Child) -> AnyView? {
			withUnsafeBytes(of: child.value) { ptr -> AnyView? in
				let binded = ptr.bindMemory(to: GenericView.self)
				return binded.first?.anyView
			}
		}
		
		let tupleMirror = Mirror(reflecting: tuple)
		return tupleMirror.children.compactMap(convert)
	}
}

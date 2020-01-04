//
//  MenuButton.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-04.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MenuButton: View {
	let title: String
	let systemImage: String
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Text(title)
			Image(systemName: systemImage)
		}
	}
}

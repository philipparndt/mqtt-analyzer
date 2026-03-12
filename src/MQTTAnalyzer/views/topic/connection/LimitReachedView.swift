//
//  ResumeConnectionView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2021-06-14.
//  Copyright © 2021 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct LimitReachedView: View {

	let message: String
	var onDismiss: (() -> Void)?
	var onOpenSettings: (() -> Void)?

	var body: some View {
		HStack {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundColor(.yellow)

			VStack(alignment: .leading, spacing: 4) {
				Text(message)
					.font(.subheadline)

				if let onOpenSettings = onOpenSettings {
					Button(action: onOpenSettings) {
						Text("Change limit")
							.font(.caption)
					}
					.buttonStyle(.bordered)
					.controlSize(.small)
				}
			}

			Spacer()

			if let onDismiss = onDismiss {
				Button(action: onDismiss) {
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(.secondary)
						.font(.title2)
				}
				.buttonStyle(.plain)
			}
		}
		.padding()
	}

}

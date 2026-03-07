//
//  QoSView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-29.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct QOSSectionView: View {
	@Binding var qos: Int

	var body: some View {
		Section(header: Text("QoS")) {
			QOSPicker(qos: $qos)
		}
	}
}

struct QOSPicker: View {
	@Binding var qos: Int

	var body: some View {
		Picker("QoS", selection: $qos) {
			Text("0").tag(0)
			Text("1").tag(1)
			Text("2").tag(2)
		}.pickerStyle(SegmentedPickerStyle())
	}
}

// MARK: - QoS Description

struct QoSDescriptionView: View {
	let qos: Int
	var compact: Bool = false

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: icon)
				.foregroundColor(color)
				.frame(width: 20)

			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(compact ? .caption : .subheadline)
					.fontWeight(.medium)
				if !compact {
					Text(description)
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
		}
	}

	private var icon: String {
		switch qos {
		case 0: return "hare"
		case 1: return "checkmark.circle"
		case 2: return "checkmark.seal"
		default: return "questionmark.circle"
		}
	}

	private var color: Color {
		switch qos {
		case 0: return .orange
		case 1: return .blue
		case 2: return .green
		default: return .gray
		}
	}

	private var title: String {
		switch qos {
		case 0: return "At most once"
		case 1: return "At least once"
		case 2: return "Exactly once"
		default: return "Unknown"
		}
	}

	private var description: String {
		switch qos {
		case 0: return "Fire and forget. Fast, no acknowledgment. Messages may be lost."
		case 1: return "Acknowledged delivery. Messages delivered at least once, may duplicate."
		case 2: return "Guaranteed single delivery. Slowest, but no duplicates or loss."
		default: return ""
		}
	}
}

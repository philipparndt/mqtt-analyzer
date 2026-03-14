//
//  LimitsFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

enum LimitType {
	case topicLimit
	case messageBatchLimit
}

struct LimitsFormView: View {
	@Binding var host: HostFormModel

	private static let minLimit: Double = 100
	private static let maxTopics: Double = 5000
	private static let maxMessagesBatch: Double = 2500
	private static let step: Double = 100

	@State private var topicSliderValue: Double = 1000
	@State private var messagesBatchSliderValue: Double = 1000
	@State private var initialized = false

	var body: some View {
		Section(header: Text("Limits")) {
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("Topics")
						.font(.headline)
					Spacer()
					Text("\(Int(topicSliderValue))")
						.font(.body.monospacedDigit())
						.foregroundStyle(.secondary)
				}
				Slider(
					value: $topicSliderValue,
					in: Self.minLimit...Self.maxTopics,
					step: Self.step
				) { editing in
					if !editing {
						host.limitTopic = String(Int(topicSliderValue))
					}
				}
			}
			.padding(.vertical, 4)

			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("Messages per batch")
						.font(.headline)
					Spacer()
					Text("\(Int(messagesBatchSliderValue))")
						.font(.body.monospacedDigit())
						.foregroundStyle(.secondary)
				}
				Slider(
					value: $messagesBatchSliderValue,
					in: Self.minLimit...Self.maxMessagesBatch,
					step: Self.step
				) { editing in
					if !editing {
						host.limitMessagesBatch = String(Int(messagesBatchSliderValue))
					}
				}
			}
			.padding(.vertical, 4)
		}
		.onAppear {
			if !initialized {
				topicSliderValue = Double(host.limitTopic) ?? 1000
				messagesBatchSliderValue = Double(host.limitMessagesBatch) ?? 1000
				initialized = true
			}
		}
	}
}

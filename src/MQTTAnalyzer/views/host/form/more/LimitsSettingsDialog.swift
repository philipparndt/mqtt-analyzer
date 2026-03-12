//
//  LimitsSettingsDialog.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-12.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct LimitsSettingsDialog: View {
	let host: Host
	let model: TopicTree
	let limitType: LimitType
	let onDismiss: () -> Void

	private static let minLimit: Double = 100
	private static let maxTopics: Double = 5000
	private static let maxMessagesBatch: Double = 2500
	private static let step: Double = 100

	@Environment(\.managedObjectContext) private var viewContext
	@State private var limitTopic: Double
	@State private var limitMessagesBatch: Double

	init(host: Host, model: TopicTree, limitType: LimitType, onDismiss: @escaping () -> Void) {
		self.host = host
		self.model = model
		self.limitType = limitType
		self.onDismiss = onDismiss
		self._limitTopic = State(initialValue: Double(host.settings.limitTopic))
		self._limitMessagesBatch = State(initialValue: Double(host.settings.limitMessagesBatch))
	}

	var body: some View {
		NavigationStack {
			Form {
				Section {
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Topics")
								.font(.headline)
							Spacer()
							Text("\(Int(limitTopic))")
								.font(.body.monospacedDigit())
								.foregroundStyle(.secondary)
						}
						Slider(
							value: $limitTopic,
							in: Self.minLimit...Self.maxTopics,
							step: Self.step
						)
					}
					.padding(.vertical, 4)
					.listRowBackground(limitType == .topicLimit ? Color.accentColor.opacity(0.1) : nil)

					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Text("Messages per batch")
								.font(.headline)
							Spacer()
							Text("\(Int(limitMessagesBatch))")
								.font(.body.monospacedDigit())
								.foregroundStyle(.secondary)
						}
						Slider(
							value: $limitMessagesBatch,
							in: Self.minLimit...Self.maxMessagesBatch,
							step: Self.step
						)
					}
					.padding(.vertical, 4)
					.listRowBackground(limitType == .messageBatchLimit ? Color.accentColor.opacity(0.1) : nil)
				} header: {
					Text("Limits")
				} footer: {
					VStack(alignment: .leading, spacing: 8) {
						Text("Increase the limit to receive more topics or messages. Higher values may impact performance.")
						Text("These settings can also be changed in the broker settings under \"More settings\".")
							.foregroundStyle(.secondary)
					}
				}
			}
			.formStyle(.grouped)
			.navigationTitle("Change Limits")
			#if !os(macOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						onDismiss()
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						save()
					}
				}
			}
		}
		#if os(macOS)
		.frame(minWidth: 450, idealWidth: 500, minHeight: 300, idealHeight: 340)
		#endif
	}

	func save() {
		host.settings.limitTopic = Int32(limitTopic)
		host.settings.limitMessagesBatch = Int32(limitMessagesBatch)

		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}

		// Reset exceeded flags so new limits take effect
		model.topicLimitExceeded = false
		model.messageLimitExceeded = false

		onDismiss()
	}
}

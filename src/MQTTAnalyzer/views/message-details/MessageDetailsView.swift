//
//  MessageView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.verticalSizeClass) private var verticalSizeClass
	let message: MsgMessage
	let host: Host

	private var contentView: some View {
		Group {
			if message.payload.isBinary {
				BinaryPayloadView(data: message.payload.data)
			}
			else if message.payload.isJSON {
				MessageDetailsJsonView(payload: message.payload)
			}
			else {
				MessageDetailsJsonView(source: message.payload.dataString, isJSON: false)
			}
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			#if os(macOS)
			HStack {
				Button {
					dismiss()
				} label: {
					HStack(spacing: 4) {
						Image(systemName: "chevron.left")
						Text("Back")
					}
				}
				.buttonStyle(.plain)
				.foregroundStyle(Color.accentColor)

				Spacer()
			}
			.padding(.horizontal)
			.padding(.top, 8)
			#endif

			#if os(iOS)
			if verticalSizeClass == .compact {
				// Landscape: side-by-side layout
				HStack(spacing: 0) {
					ScrollView {
						MetadataView(message: message, host: host)
					}
					.frame(width: 320)

					contentView
				}
			} else {
				// Portrait: stacked layout
				VStack {
					MetadataView(message: message, host: host)
					contentView
				}
			}
			#else
			VStack {
				MetadataView(message: message, host: host)
				contentView
			}
			#endif
		}
		#if os(macOS)
		.navigationBarBackButtonHidden(true)
		#endif
	}
}

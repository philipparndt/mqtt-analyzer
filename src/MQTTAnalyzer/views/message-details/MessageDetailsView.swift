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
	let message: MsgMessage
	let host: Host

	var body: some View {
		VStack {
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

			VStack {
				MetadataView(message: message, host: host)

				if message.payload.isBinary {
					MessageDetailsJsonView(source: self.message.payload.data.hexBlockEncoded(len: 12))
				}
				else if message.payload.isJSON {
					MessageDetailsJsonView(source: message.payload.prettyJSON)
				}
				else {
					MessageDetailsJsonView(source: message.payload.dataString)
				}
			}
		}
		#if os(macOS)
		.navigationBarBackButtonHidden(true)
		#endif
	}
}

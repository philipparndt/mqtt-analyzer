//
//  MessageView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsView: View {
	let message: MsgMessage
	
	var body: some View {
		VStack {
			VStack {
				MetadataView(message: message)

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
	}
}

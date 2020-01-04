//
//  MessageDetailsJsonView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageDetailsJsonView: View {
	let message: JsonFormatString
	
	// Workaround: update triggered due to change on this state
	@State var workaroundUpdate = false
	
	var body: some View {
		VStack {
			AttributedUILabel(attributedString: message.getAttributed(), workaroundUpdate: self.$workaroundUpdate)
		}
		.frame(height: message.getAttributed().height(withConstrainedWidth: 500), alignment: .top)
	}
}

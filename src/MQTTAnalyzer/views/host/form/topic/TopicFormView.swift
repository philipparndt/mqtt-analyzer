//
//  TopicFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct TopicFormView: View {
	@Binding var host: HostFormModel

	var body: some View {
		return Section(header: Text("Subscribe to")) {
			HStack {
				Text("Topic")
					.font(.headline)
				
				Spacer()
//				TextField("#", text: $host.topics)
//					.multilineTextAlignment(.trailing)
//					.disableAutocorrection(true)
//					.autocapitalization(.none)
//					.font(.body)
			}
			
			HStack {
				Text("QoS")
				.font(.headline)
				
				Spacer()
				
				QOSPicker(qos: $host.qos)
			}
		}
	}
}

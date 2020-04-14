//
//  LimitsFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct LimitsFormView: View {
	@Binding var host: HostFormModel
	
	var limitTopicInvalid: Bool {
		return HostFormValidator.validateMaxTopic(value: host.limitTopic) == nil
	}
	
	var limitMessagesBatchInvalid: Bool {
		return HostFormValidator.validateMaxMessagesBatch(value: host.limitMessagesBatch) == nil
	}
	
	var body: some View {
		return Section(header: Text("Limits")) {
			HStack {
				FormFieldInvalidMark(invalid: limitTopicInvalid)
				
				Text("Topics")
					.font(.headline)
				
				Spacer()
			
				TextField("250", text: $host.limitTopic)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
			
			HStack {
				FormFieldInvalidMark(invalid: limitMessagesBatchInvalid)
				
				Text("Message per batch")
					.font(.headline)
				
				Spacer()
			
				TextField("1000", text: $host.limitMessagesBatch)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

//
//  ClientIDFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ClientIDFormView: View {
	@Binding var host: HostFormModel
	
	var body: some View {
		return Section(header: Text("Client ID")) {
			HStack {
				Text("Client ID")
					.font(.headline)
				
				Spacer()
			
				TextField("Random by default", text: $host.clientID)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

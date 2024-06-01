//
//  CategoryFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 01.06.24.
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct CategoryFormView: View {
	@Binding var host: HostFormModel
	
	var body: some View {
		return Section(header: Text("Category")) {
			HStack {
				Text("Category")
					.font(.headline)
				
				Spacer()
			
				TextField("No category", text: $host.category)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

//
//  NavigationModeVie.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-28.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct NavigationModeFormView: View {
	@Binding var host: HostFormModel
	var maxMessagesOfSubFoldersInvalid: Bool {
		return HostFormValidator.validateMaxMessagesOfSubFolders(value: host.maxMessagesOfSubFolders) == nil
	}
	
	var body: some View {
		return Section(header: Text("View")) {
			HStack {
				Text("Navigation")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				NavigationPicker(type: $host.navigation)
			}
			
			if host.navigation == .folders {
				HStack {
					FormFieldInvalidMark(invalid: maxMessagesOfSubFoldersInvalid)

					Text("Max messages of subfolders")
						.font(.headline)

					Spacer()

					TextField("10", text: $host.maxMessagesOfSubFolders)
						.multilineTextAlignment(.trailing)
						.disableAutocorrection(true)
						.font(.body)
				}
			}
		}
	}
	
	func updateSettingsForAWSIOT() {
		self.host.updateSettingsForAWSIOT()
	}
}

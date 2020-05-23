//
//  PKCS12HelpView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct PKCS12HelpView: View {
	var body: some View {
		Section(header: Text("Use openssl to create PKCS#12 files:")) {
			VStack(alignment: .leading) {
				HStack {
					Text("openssl pkcs12 -export -in user.crt -inkey user.key -out user.p12")
						.font(.system(size: 14, design: .monospaced))
						.foregroundColor(.secondary)
	
					Spacer()
				}
			}
			.padding(5)
			.background(Color.gray.opacity(0.2))
		}
	}
}

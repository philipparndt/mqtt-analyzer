//
//  ConnectingView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ConnectingView: View {
	var host: Host
	
	var body: some View {
		HStack {
			Text(host.connectionMessage ?? "Connecting...")
			
			Spacer()
		}
		.padding()
	}
}

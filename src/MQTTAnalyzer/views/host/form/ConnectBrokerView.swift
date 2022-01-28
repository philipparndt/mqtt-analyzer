//
//  DisconnectedView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-04.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ConnectBrokerView: View {
	let connect: () -> Void
	
	var body: some View {
		HStack {
			Spacer()
			
			Button(action: connect) {
				HStack {
					Image(systemName: "play.fill")
					
					Text("Connect")
				}
			}
		}
		.padding()
    }
}

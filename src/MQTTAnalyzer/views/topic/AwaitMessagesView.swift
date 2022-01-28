//
//  AwaitMessagesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-28.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct AwaitMessagesView: View {
	@ObservedObject var model: MessageModel
	@ObservedObject var host: Host
	
    var body: some View {
		List {
			TopicsToolsView(model: self.model)
		}
		.listStyle(GroupedListStyle())
		.frame(height: 200, alignment: .top)
		
		HStack {
			if host.state == .connected {
				ProgressView()
				   .progressViewStyle(CircularProgressViewStyle())
				
				Text("Waiting for messages").padding([.leading])
			}
			else if host.state == .connecting {
				ProgressView()
				   .progressViewStyle(CircularProgressViewStyle())
				
				Text("Connecting").padding([.leading])
			}
			else {
				Text("Not connected").padding([.leading])
			}
		}
		Spacer()
    }
}

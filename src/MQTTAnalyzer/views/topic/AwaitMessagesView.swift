//
//  AwaitMessagesView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-01-28.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct AwaitMessagesView: View {
	@ObservedObject var model: TopicTree
	@ObservedObject var host: Host
	@Environment(\.colorScheme) var colorScheme

    var body: some View {
		VStack {
			VStack(alignment: .leading) {
				Divider()
				TopicsToolsView(model: self.model)
				Divider()
			}
			.padding([.horizontal, .top], 8)
			.background(Color.listItemBackground(colorScheme))
			
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
			.padding([.top], 40)
			Spacer()
		}
		.background(Color.listBackground(colorScheme))
    }
}

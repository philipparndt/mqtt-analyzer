//
//  HostCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostCellView: View {
	@EnvironmentObject var model: RootModel
	@ObservedObject var host: Host

	var messageModel: MessageModel
	
	@State var editHostPresented = false
	
	var connectionColor: Color {
		host.connected ? .green : .gray
	}
	
	var body: some View {
		NavigationLink(destination: TopicsView(model: messageModel, host: host, dialogPresented: host.needsAuth)) {
			HStack {
				VStack(alignment: .leading) {
					Text(host.alias)
					Spacer()
					Group {
						Text("\(host.hostname)")
						Text(host.topic)
					}
					.font(.footnote)
					.foregroundColor(.secondary)
				}
				
				Spacer()

				if host.connected || host.connecting {
					Image(systemName: "circle.fill")
						.font(.subheadline)
						.foregroundColor(connectionColor)
				}
			}
			.contextMenu {
				MenuButton(title: "Edit", systemImage: "pencil.circle", action: editHost)
				if host.connected || host.connecting {
					MenuButton(title: "Disconnect", systemImage: "stop.circle", action: disconnect)
				}
			}
		}.sheet(isPresented: $editHostPresented, onDismiss: cancelEditCreation, content: {
			
			EditHostFormModalView(closeHandler: self.cancelEditCreation,
								  root: self.model,
								  hosts: self.model.hostsModel,
								  original: self.host,
								  host: self.transformHost(),
								  auth: self.host.auth)
		})
	}
	
	func transformHost() -> HostFormModel {
		return HostFormModel(alias: host.alias,
							 hostname: host.hostname,
							 port: "\(host.port)",
							 topic: host.topic,
							 qos: host.qos,
							 username: host.username,
							 password: host.password)
	}
	
	func editHost() {
		editHostPresented = true
	}
	
	func disconnect() {
		host.disconnect()
	}
	
	func cancelEditCreation() {
		editHostPresented = false
	}
}

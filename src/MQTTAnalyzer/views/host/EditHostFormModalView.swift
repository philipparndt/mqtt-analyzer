//
//  EditHostFormModalView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: Edit Host
struct EditHostFormModalView: View {
	let closeHandler: () -> Void
	let root: RootModel
	var hosts: HostsModel = HostsModel()
	let original: Host
	
	@State var host: HostFormModel
	@State var auth: Bool = false

	var body: some View {
		NavigationView {
			EditHostFormView(host: $host, auth: $auth)
				.font(.caption)
				.navigationBarTitle(Text("Edit host"))
				.navigationBarItems(
					leading: Button(action: cancel) { Text("Cancel") },
					trailing: Button(action: save) { Text("Save") }
			)
		}
	}
	
	func save() {
		original.alias = host.alias
		original.hostname = host.hostname
		original.qos = host.qos
		original.auth = self.auth
		original.port = Int32(host.port) ?? 1883
		original.topic = host.topic
		original.clientID = host.clientID
		original.limitTopic = Int(host.limitTopic) ?? 250
		original.limitMessagesBatch = Int(host.limitMessagesBatch) ?? 1000
		
		if self.auth {
			original.username = host.username
			original.password = host.password
		}
		else {
			original.username = ""
			original.password = ""
		}
		
		root.persistence.update(original)
	}
	
	func cancel() {
		closeHandler()
	}
}

//
//  NewHostFormModalView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import swift_petitparser

// MARK: Create Host
struct NewHostFormModalView: View {
	let closeHandler: () -> Void
	let root: RootModel
	var hosts: HostsModel
	
	@State private var host: HostFormModel = HostFormModel()
	@State private var auth: HostAuthenticationType = .none
	@State private var connectionMethod: HostProtocol = .mqtt
	@State private var clientImpl: HostClientImplType = .cocoamqtt
	
	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
			|| HostFormValidator.validateMaxTopic(value: host.limitTopic) == nil
			|| HostFormValidator.validateMaxMessagesBatch(value: host.limitMessagesBatch) == nil
	}
	
	var body: some View {
		NavigationView {
			EditHostFormView(host: $host, auth: $auth, connectionMethod: $connectionMethod, clientImpl: $clientImpl)
				.font(.caption)
				.navigationBarTitle(Text("New host"))
				.navigationBarItems(
					leading: Button(action: cancel) {
						Text("Cancel")
						
					}.buttonStyle(ActionStyleLeading()),
					
					trailing: Button(action: save) {
						Text("Save")
					}.buttonStyle(ActionStyleTrailing()).disabled(disableSave)
			)
		}
	}
	
	func save() {
		let newHost = copyHost(target: Host(), source: host, auth, connectionMethod, clientImpl)
		if newHost == nil {
			return
		}
		
		DispatchQueue.main.async {
			self.hosts.hosts.append(newHost!)
			self.root.persistence.create(newHost!)
			
			self.closeHandler()
		}
	}
	
	func cancel() {
		closeHandler()
	}
}

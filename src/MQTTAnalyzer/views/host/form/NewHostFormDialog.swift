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
	
	@State var host: HostFormModel
	
	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
			|| HostFormValidator.validateMaxTopic(value: host.limitTopic) == nil
			|| HostFormValidator.validateMaxMessagesBatch(value: host.limitMessagesBatch) == nil
	}
	
	var body: some View {
		NavigationView {
			EditHostFormView(host: $host)
				.font(.caption)
				.navigationBarTitle(Text("New server"), displayMode: .inline)
				.navigationBarItems(
					leading: Button(action: cancel) {
						Text("Cancel")
						
					}.buttonStyle(ActionStyleT50()),
					
					trailing: Button(action: save) {
						Text("Save")
					}.buttonStyle(ActionStyleL50()).disabled(disableSave)
			)
		}.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func save() {
		let newHost = copyHost(target: Host(), source: host)
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

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
	var hosts: HostsModel = HostsModel(initMethod: RootModel.controller)
	let original: Host
	
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
				.navigationBarTitle(Text("Edit server"), displayMode: .inline)
				.navigationBarItems(
					leading: Button(action: cancel) { Text("Cancel") },
					trailing: Button(action: save) { Text("Save") }.disabled(disableSave)
			)
		}.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func save() {
		let updated = copyHost(target: original, source: host)
		if updated == nil {
			return
		}
		
		DispatchQueue.main.async {
			self.root.persistence.update(updated!)
			self.closeHandler()
		}
	}
	
	func cancel() {
		closeHandler()
	}
}

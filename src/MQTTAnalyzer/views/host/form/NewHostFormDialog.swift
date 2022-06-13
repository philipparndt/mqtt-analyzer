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
	@State var errorMessage: String?
	
	@Environment(\.managedObjectContext) private var viewContext
	@State var host: HostFormModel
	
	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
			|| HostFormValidator.validateMaxTopic(value: host.limitTopic) == nil
			|| HostFormValidator.validateMaxMessagesBatch(value: host.limitMessagesBatch) == nil
	}
	
	var body: some View {
		NavigationView {
			if let message = errorMessage {
				Text(message).foregroundColor(.red)
			}
			
			EditHostFormView(onDelete: closeHandler, host: $host)
				.font(.caption)
				.navigationBarTitleDisplayMode(.inline)
				.navigationTitle("New broker")
				.toolbar {
					ToolbarItemGroup(placement: .navigationBarLeading) {
						Button(action: cancel) {
							Text("Cancel")
						}
					}
					ToolbarItemGroup(placement: .navigationBarTrailing) {
						Button(action: save) {
							Text("Save")
						}.disabled(disableSave)
					}
				}
		}.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func save() {
		if !validate(source: host) {
			return
		}
		
		do {
			let broker = BrokerSetting(context: viewContext)
			broker.id = UUID()
			try copyBroker(target: broker, source: host)
			
			try viewContext.save()
			DispatchQueue.main.async {
				self.closeHandler()
			}
		} catch {
			let nsError = error as NSError
			errorMessage = "Unresolved error \(nsError), \(nsError.userInfo)"
		}
	}
	
	func cancel() {
		closeHandler()
	}
}

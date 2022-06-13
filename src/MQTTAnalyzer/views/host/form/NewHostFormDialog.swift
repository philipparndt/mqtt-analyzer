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
		let broker = BrokerSetting(context: viewContext)
		
		let newHost = copyBroker(target: broker, source: host)
		if newHost == nil {
			return
		}
		
		do {
			try viewContext.save()
						
			DispatchQueue.main.async {
				self.closeHandler()
			}
		} catch {
			// FIXME: implement
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			// let nsError = error as NSError
			// fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	func cancel() {
		closeHandler()
	}
}

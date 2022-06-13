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
	let original: BrokerSetting
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
			EditHostFormView(onDelete: delete, host: $host)
				.font(.caption)
				.navigationBarTitleDisplayMode(.inline)
				.navigationTitle("Edit broker")
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
			try copyBroker(target: original, source: host)
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		
		DispatchQueue.main.async {
			self.closeHandler()
		}
	}
	
	func delete() {
		DispatchQueue.main.async {
			viewContext.delete(original)
			do {
				try viewContext.save()
			} catch {
				let nsError = error as NSError
				NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
			}

			self.closeHandler()
		}
	}
	
	func cancel() {
		closeHandler()
	}
}

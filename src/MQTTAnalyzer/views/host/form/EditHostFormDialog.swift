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
	@State private var showDiagnostics = false
	@State private var confirmDelete = false

	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
	}

	var body: some View {
		NavigationStack {
			EditHostFormView(onDelete: delete, host: $host)
				.font(.caption)
				#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
				.navigationTitle("Edit broker")
				.toolbar {
				   ToolbarItemGroup(placement: .cancellationAction) {
					   Button(action: cancel) {
						   Text("Cancel")
					   }
				   }
				   #if os(macOS)
				   ToolbarItemGroup(placement: .automatic) {
					   Button(role: .destructive) {
						   confirmDelete = true
					   } label: {
						   Label("Delete", systemImage: "trash")
					   }

					   Button {
						   showDiagnostics = true
					   } label: {
						   Label("Test Connection", systemImage: "stethoscope")
					   }
					   .disabled(disableSave)
				   }
				   #endif
				   ToolbarItemGroup(placement: .confirmationAction) {
					   Button(action: save) {
						   Text("Save")
					   }.disabled(disableSave)
				   }
				}
		}
		.confirmationDialog("Are you sure you want to delete the broker setting?",
						   isPresented: $confirmDelete) {
			Button("Delete", role: .destructive) {
				delete()
			}
		}
		#if os(macOS)
		.frame(minWidth: 500, idealWidth: 550, minHeight: 500, idealHeight: 600)
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(
				hostname: host.hostname,
				port: Int(host.port) ?? 1883,
				ssl: host.ssl,
				untrustedSSL: host.untrustedSSL,
				protocolMethod: host.protocolMethod,
				isPresented: $showDiagnostics,
				formModel: $host
			)
		}
		#endif
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

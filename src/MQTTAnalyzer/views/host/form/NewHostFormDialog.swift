//
//  NewHostFormModalView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: Create Host
struct NewHostFormModalView: View {
	let closeHandler: () -> Void
	let root: RootModel
	var hosts: HostsModel
	@State var errorMessage: String?
	
	@Environment(\.managedObjectContext) private var viewContext
	@State var host: HostFormModel
	@State private var showDiagnostics = false

	var disableSave: Bool {
		return HostFormValidator.validateHostname(name: host.hostname) == nil
			|| HostFormValidator.validatePort(port: host.port) == nil
	}
	
	var body: some View {
		NavigationStack {
			if let message = errorMessage {
				Text(message).foregroundColor(.red)
			}

			EditHostFormView(onDelete: closeHandler, host: $host)
				.font(.caption)
				#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
				.navigationTitle("New broker")
				.toolbar {
					ToolbarItemGroup(placement: .cancellationAction) {
						Button(action: cancel) {
							Text("Cancel")
						}
					}
					#if os(macOS)
					ToolbarItemGroup(placement: .automatic) {
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

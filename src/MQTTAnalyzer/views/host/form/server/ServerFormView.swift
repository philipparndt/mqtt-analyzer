//
//  ServerFormView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct ServerFormView: View {
	@Binding var host: HostFormModel

	var hostnameInvalid: Bool {
		return !host.hostname.isEmpty
			&& HostFormValidator.validateHostname(name: host.hostname) == nil
	}

	var portInvalid: Bool {
		return HostFormValidator.validatePort(port: host.port) == nil
	}

	var body: some View {
		return Section(header: Text("Server")) {
			HStack {
				Text("Alias")
					.foregroundColor(.secondary)
					.font(.headline)
				
				Spacer()
				
				TextField("optional", text: $host.alias)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.accessibilityLabel("alias")
					.font(.body)
			}
			HStack {
				FormFieldInvalidMark(invalid: hostnameInvalid)
				
				Text("Hostname")
					.font(.headline)

				Spacer()

				TextField("ip address / name", text: $host.hostname)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.accessibilityLabel("hostname")
					.font(.body)
			}
			
			if host.isAWS() {
				AWSIoTHelpView(host: $host)
			}
			else if host.isClientCerts() {
				ClientCertsHelpView(host: $host)
			}
			
			HStack {
				FormFieldInvalidMark(invalid: portInvalid)

				Text("Port")
					.font(.headline)

				Spacer()

				TextField("e.g. 1883", text: $host.port)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.accessibilityLabel("port")
					.font(.body)
			}
			
			HStack {
				Text("Protocol")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				ProtocolPicker(type: $host.protocolMethod)
			}
			
			HStack {
				Text("Version")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				ProtocolVersionPicker(version: $host.protocolVersion)
			}
			
			if host.protocolMethod == .websocket {
				HStack {
					Text("Basepath")
						.font(.headline)
					
					Spacer()
					
					TextField("/", text: $host.basePath)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.font(.body)
				}
			}
			
			Toggle(isOn: $host.ssl) {
				Text("TLS")
					.font(.headline)
			}.accessibilityLabel("tls")

			if host.ssl {
				Toggle(isOn: $host.untrustedSSL) {
					Text("Allow untrusted")
						.font(.headline)
				}
			}
		}
	}
	
}

//
//  NewHostFormView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-25.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostFormModel {
	var alias: String = ""
	var hostname: String = ""
	var port: String = "1883"
	var basePath: String = ""
	var topic: String = "#"
	
	var qos: Int = 0
	
	var username: String = ""
	var password: String = ""
	
	var certServerCA: String = ""
	var certClient: String = ""
	var certClientKey: String = ""
	var certClientKeyPassword: String = ""
	
	var clientID = ""
	
	var limitTopic = "250"
	var limitMessagesBatch = "1000"
}

struct EditHostFormView: View {
	@Binding var host: HostFormModel
	@Binding var auth: HostAuthenticationType
	@Binding var connectionMethod: HostProtocol
	@Binding var clientImpl: HostClientImplType
	@State var advanced = false
	
	var body: some View {
		Form {
			ServerFormView(host: $host, protocolMethod: $connectionMethod, clientImpl: $clientImpl)
			AuthFormView(host: $host, type: $auth)
			TopicFormView(host: $host)
			
			Toggle(isOn: $advanced) {
				Text("More settings")
					.font(.headline)
			}
			
			if self.advanced {
				ClientIDFormView(host: $host)
				LimitsFormView(host: $host)
			}
		}.keyboardResponsive()
	}
}

struct FormFieldInvalidMark: View {
	var invalid: Bool
	
	var body: some View {
		Group {
			if invalid {
				Image(systemName: "xmark.octagon.fill")
				.font(.headline)
					.foregroundColor(.red)
			}
		}
	}
}

// MARK: Server
struct ServerFormView: View {
	@Binding var host: HostFormModel
	@Binding var protocolMethod: HostProtocol
	@Binding var clientImpl: HostClientImplType

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
					.font(.body)
			}
			HStack {
				FormFieldInvalidMark(invalid: portInvalid)

				Text("Port")
					.font(.headline)

				Spacer()

				TextField("1883", text: $host.port)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.font(.body)
			}
			
			HStack {
				Text("Protocol")
					.font(.headline)
					.frame(minWidth: 100, alignment: .leading)

				Spacer()

				ProtocolPicker(type: $protocolMethod)
			}
			
			if protocolMethod == .mqtt {
				HStack {
					Text("Client")
						.font(.headline)
						.frame(minWidth: 100, alignment: .leading)
					
					Spacer()
					
					ClientImplTypePicker(type: $clientImpl)
				}
			}
				
			if protocolMethod == .websocket {
				HStack {
					Text("Basepath")
						.font(.headline)
					
					Spacer()
					
					TextField("/", text: $host.basePath)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.font(.body)
				}
			}
		}
	}
}

// MARK: Topic
struct TopicFormView: View {
	@Binding var host: HostFormModel

	var body: some View {
		return Section(header: Text("Subscribe to")) {
			HStack {
				Text("Topic")
					.font(.headline)
				
				Spacer()
				
				TextField("#", text: $host.topic)
					.multilineTextAlignment(.trailing)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.font(.body)
			}
			
			HStack {
				Text("QoS")
				.font(.headline)
				
				Spacer()
				
				QOSPicker(qos: $host.qos)
			}
		}
	}
}

// MARK: ClientID
struct ClientIDFormView: View {
	@Binding var host: HostFormModel
	
	var body: some View {
		return Section(header: Text("Client ID")) {
			HStack {
				Text("Client ID")
					.font(.headline)
				
				Spacer()
			
				TextField("Random by default", text: $host.clientID)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

struct LimitsFormView: View {
	@Binding var host: HostFormModel
	
	var limitTopicInvalid: Bool {
		return HostFormValidator.validateMaxTopic(value: host.limitTopic) == nil
	}
	
	var limitMessagesBatchInvalid: Bool {
		return HostFormValidator.validateMaxMessagesBatch(value: host.limitMessagesBatch) == nil
	}
	
	var body: some View {
		return Section(header: Text("Limits")) {
			HStack {
				FormFieldInvalidMark(invalid: limitTopicInvalid)
				
				Text("Topics")
					.font(.headline)
				
				Spacer()
			
				TextField("250", text: $host.limitTopic)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
			
			HStack {
				FormFieldInvalidMark(invalid: limitMessagesBatchInvalid)
				
				Text("Message per batch")
					.font(.headline)
				
				Spacer()
			
				TextField("1000", text: $host.limitMessagesBatch)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.multilineTextAlignment(.trailing)
					.font(.body)
			}
		}
	}
}

// MARK: Auth
struct AuthFormView: View {
	@Binding var host: HostFormModel
	@Binding var type: HostAuthenticationType
	
	var body: some View {
		return Section(header: Text("Authentication")) {
			AuthenticationTypePicker(type: $type)
			
			if self.type == .usernamePassword {
				UsernamePasswordAuthenticationView(host: $host)
			}
			else if self.type == .certificate {
				CertificateAuthenticationView(host: $host)
			}
		}
	}
}

#if DEBUG
//struct NewHostFormView_Previews : PreviewProvider {
//	static var previews: some View {
//		NavigationView {
//			NewHostFormView(host: Host())
//		}
//	}
//}
#endif

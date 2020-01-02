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
    var topic: String = "#"
    
    var qos: Int = 0
    
    var username: String = ""
    var password: String = ""
}

struct EditHostFormView: View {
    @Binding var host: HostFormModel
    @Binding var auth: Bool
    
    var body: some View {
		Group {
			Form {
				ServerFormView(host: $host)
				TopicFormView(host: $host)
				AuthFormView(host: $host, auth: $auth)
				Spacer().frame(height: 300) // Keyboard scoll spacer
			}
		}
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

// MARK: Auth
struct AuthFormView: View {
    @Binding var host: HostFormModel
    @Binding var auth: Bool

    var body: some View {
        return Section(header: Text("Authentification")) {
            Toggle(isOn: $auth) {
                Text("Use auth")
                    .font(.headline)
            }
            
            if self.auth {
                HStack {
                    Text("Username")
                        .font(.headline)
                    
                    Spacer()
                
                    TextField("username", text: $host.username)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                        .font(.body)
                }
                
                HStack {
                    Text("Password")
                        .font(.headline)
                    
                        Spacer()
                    
                    SecureField("password", text: $host.password)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .multilineTextAlignment(.trailing)
                        .font(.body)
                }
            }
        }
    }
}

#if DEBUG
//struct NewHostFormView_Previews : PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            NewHostFormView(host: Host())
//        }
//    }
//}
#endif

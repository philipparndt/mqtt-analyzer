//
//  NewHostFormView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-25.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostFormModel {
    var alias : String = ""
    var hostname : String = ""
    var port : String = "1883"
    var topic : String = "#"
    
    var qos : Int = 0
    
    var username : String = ""
    var password : String = ""
}

struct NewHostFormModalView : View {
    @Binding var isPresented : Bool
    var hosts: HostsModel

    @State private var host : HostFormModel = HostFormModel()
    @State private var auth : Bool = false
    
    var body: some View {
        NavigationView {
            NewHostFormView(host: $host, auth: $auth)
                .font(.caption)
                .navigationBarTitle(Text("New host"))
                .navigationBarItems(
                    leading: Button(action: cancel) { Text("Cancel") },
                    trailing: Button(action: save) { Text("Save") }
            )
        }
    }
    
    func save() {
        let myHost = Host()
        myHost.alias = host.alias
        myHost.hostname = host.hostname
        myHost.qos = host.qos
        myHost.auth = self.auth
        myHost.port = UInt16(host.port) ?? 1883
        myHost.topic = host.topic
        
        if (self.auth) {
            myHost.username = host.username
            myHost.password = host.password
        }
        
        hosts.hosts.append(myHost)
        
        self.isPresented = false
        clear()
    }
    
    func cancel() {
        self.isPresented = false
        clear()
    }
    
    
    func clear() {
        host = HostFormModel()
        auth = false
    }
}

struct NewHostFormView : View {
    @Binding var host : HostFormModel
    @Binding var auth : Bool
    
    var body: some View {
        Form {
            ServerFormView(host: $host)
            TopicFormView(host: $host)
            AuthFormView(host: $host, auth: $auth)
        }
    }
}

// MARK: Server
struct ServerFormView : View {
    @Binding var host : HostFormModel
    
    var body: some View {
        return Section(header: Text("Server")) {
            HStack {
                Text("Alias")
                    .foregroundColor(.secondary)
                    .font(.headline)
                Spacer()

                TextField($host.alias, placeholder: Text("optional"))
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Hostname")
                    .font(.headline)

                Spacer()

                TextField($host.hostname, placeholder: Text("ip address / name"))
                .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Port")
                .font(.headline)

                Spacer()

                TextField($host.port, placeholder: Text("1883"))
                .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: Topic
struct TopicFormView : View {
    @Binding var host : HostFormModel

    var body: some View {
        return Section(header: Text("Subscribe to")) {
            HStack {
                Text("Topic")
                    .font(.headline)
                
                Spacer()
                
                TextField($host.topic, placeholder: Text("#"))
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("QoS")
                    .font(.headline)
                
                Spacer()
                
                SegmentedControl(selection: $host.qos) {
                    Text("0").tag(0)
                    Text("1").tag(1)
                    Text("2").tag(2)
                }
            }
        }
    }
}

// MARK: Auth
struct AuthFormView : View {
    @Binding var host : HostFormModel
    @Binding var auth : Bool

    var body: some View {
        return Section(header: Text("Authentification")) {
            Toggle(isOn: $auth) {
                Text("Use auth")
                    .font(.headline)
            }
            
            if (self.auth) {
                HStack {
                    Text("Username")
                        .font(.headline)
                    
                    Spacer()
                
                    TextField($host.username)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Password")
                        .font(.headline)
                    
                        Spacer()
                    
                        SecureField($host.password)
                            .multilineTextAlignment(.trailing)
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

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
    let root : RootModel
    var hosts: HostsModel
    
    @State private var host : HostFormModel = HostFormModel()
    @State private var auth : Bool = false
    
    
    var body: some View {
        NavigationView {
            EditHostFormView(host: $host, auth: $auth)
                .font(.caption)
                .navigationBarTitle(Text("New host"))
                .navigationBarItems(
                    leading: Button(action: cancel) { Text("Cancel") },
                    trailing: Button(action: save) { Text("Save") }
            )
        }
    }
    
    func save() {
        let newHost =  Host()
        newHost.alias = host.alias
        newHost.hostname = host.hostname
        newHost.qos = host.qos
        newHost.auth = self.auth
        newHost.port = Int32(host.port) ?? 1883
        newHost.topic = host.topic
        
        if (self.auth) {
            newHost.username = host.username
            newHost.password = host.password
        }
        
        hosts.hosts.append(newHost)
        
        root.persistence.create(newHost)
        
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

struct EditHostFormModalView : View {
    @Binding var isPresented : Bool
    let root : RootModel
    var hosts: HostsModel
    let original : Host
    
    @State var host : HostFormModel
    @State private var auth : Bool = false
    
    var body: some View {
        NavigationView {
            EditHostFormView(host: $host, auth: $auth)
                .font(.caption)
                .navigationBarTitle(Text("Edit host"))
                .navigationBarItems(
                    leading: Button(action: cancel) { Text("Cancel") },
                    trailing: Button(action: save) { Text("Save") }
            )
        }
    }
    
    func save() {
        original.alias = host.alias
        original.hostname = host.hostname
        original.qos = host.qos
        original.auth = self.auth
        original.port = Int32(host.port) ?? 1883
        original.topic = host.topic
        
        if (self.auth) {
            original.username = host.username
            original.password = host.password
        }
        else {
            original.username = ""
            original.password = ""
        }
        
        root.persistence.update(original)

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

struct EditHostFormView : View {
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
                
                TextField("optional", text: $host.alias)
                    .multilineTextAlignment(.trailing)
                    .disableAutocorrection(true)
            }
            HStack {
                Text("Hostname")
                    .font(.headline)

                Spacer()

                TextField("ip address / name", text: $host.hostname)
                    .multilineTextAlignment(.trailing)
                    .disableAutocorrection(true)
            }
            HStack {
                Text("Port")
                    .font(.headline)

                Spacer()

                TextField("1883", text: $host.port)
                    .multilineTextAlignment(.trailing)
                    .disableAutocorrection(true)
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
                
                TextField("#", text: $host.topic)
                    .multilineTextAlignment(.trailing)
                    .disableAutocorrection(true)
            }
            
            HStack {
                Text("QoS")
                .font(.headline)
                
                Spacer()
                
                Picker(selection: $host.qos, label: Text("QoS")) {
                    Text("0").tag(0)
                    Text("1").tag(1)
                    Text("2").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
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
                
                    TextField("username", text: $host.username)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Password")
                        .font(.headline)
                    
                        Spacer()
                    
                    SecureField("password", text: $host.password)
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

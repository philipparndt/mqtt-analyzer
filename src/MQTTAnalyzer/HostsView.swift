//
//  HostsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostsView : View {
    @EnvironmentObject var model : RootModel

    @State
    var isPresented = false

    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                List {
                    ForEach(model.hostsModel.hosts) { host in
                        HostCell(host: host, messageModel: (
                            self.model.getMessageModel(host)
                        ))
                    }
                }
            }
            .navigationBarItems(
                trailing: Button(action: createHost ) {
                    HStack {
                        Image(systemName: "plus")
                         .font(.body)
                    }
                }
            )
            .navigationBarTitle(Text("Servers"), displayMode: .inline)
        }
        .sheet(isPresented: $isPresented, onDismiss: cancelHostCreation, content: {
            NewHostFormModalView(isPresented: self.$isPresented, hosts: self.model.hostsModel)
        })
    }
    
    func createHost() {
        isPresented = true
    }
    
    func cancelHostCreation() {
         isPresented = false
    }
}

struct HostCell : View {
    var host: Host
    @EnvironmentObject var model : RootModel

    var messageModel: MessageModel
    
    var body: some View {
        NavigationLink(destination: TopicsView(model: messageModel, host: host)) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(host.connected ? .green : .red)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text(host.alias)
                    .font(.title)
                    .padding([.bottom])
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("hostname:")
                                .disableAutocorrection(true)
                            Text("topic:")
                                .disableAutocorrection(true)
                        }.foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text("\(host.hostname)")
                            Text(host.topic)
                        }
                    }
                }
            }
        }
    }
}
#if DEBUG
//struct HostsView_Previews : PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            HostsView(hosts : HostsModel.sampleModel())
//        }
//    }
//}
#endif

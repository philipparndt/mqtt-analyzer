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
    var createHostPresented = false
    
    @ObservedObject
    var hostsModel : HostsModel

    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                List {
                    ForEach(hostsModel.hosts) { host in
                        HostCellView(host: host, messageModel: (
                            self.model.getMessageModel(host)
                        ))
                    }
                    .onDelete(perform: hostsModel.delete)
                }
            }
            .navigationBarItems(
                trailing: Button(action: createHost) {
                    Image(systemName: "plus")
                }
                .buttonStyle(ActionStyle())
            )
            .navigationBarTitle(Text("Servers"), displayMode: .inline)
        }
        .sheet(isPresented: $createHostPresented, onDismiss: cancelHostCreation, content: {
            NewHostFormModalView(isPresented: self.$createHostPresented, hosts: self.model.hostsModel)
        })

    }
    
    func createHost() {
        createHostPresented = true
    }
    
    func cancelHostCreation() {
        createHostPresented = false
    }
}

struct ActionStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .foregroundColor(.accentColor)
            .font(.system(size: 22))
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

//
//  HostsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct HostsView: View {
    @EnvironmentObject var model: RootModel
    @State var createHostPresented = false
    @ObservedObject var hostsModel: HostsModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    ForEach(hostsModel.hosts) { host in
                        HostCellView(host: host, messageModel: (
                            self.model.getMessageModel(host)
                        ))
                    }
                    .onDelete(perform: self.delete)
                }
            }
            .navigationBarItems(
                trailing: Button(action: createHost) {
                    Image(systemName: "plus")
                }
                .font(.system(size: 22))
                .buttonStyle(ActionStyleTrailing())
            )
            .navigationBarTitle(Text("Servers"), displayMode: .inline)
        }
        .sheet(isPresented: $createHostPresented, onDismiss: cancelHostCreation, content: {
            NewHostFormModalView(isPresented: self.$createHostPresented,
                                 root: self.model,
                                 hosts: self.model.hostsModel)
        })

    }
    
    func delete(at indexSet: IndexSet) {
        hostsModel.delete(at: indexSet, persistence: model.persistence)
    }
    
    func createHost() {
        createHostPresented = true
    }
    
    func cancelHostCreation() {
        createHostPresented = false
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

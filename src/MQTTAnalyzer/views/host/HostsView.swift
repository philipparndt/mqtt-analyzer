//
//  HostsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

enum HostsSheetType {
	case none
	case about
	case createHost
}

struct HostsView: View {
	@EnvironmentObject var model: RootModel
	@ObservedObject var hostsModel: HostsModel

	@State var presented = false
	@State var sheetType: HostsSheetType = .none
	
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
				leading: Button(action: showAbout) {
					Text("About")
				},
				trailing: Button(action: createHost) {
					Image(systemName: "plus")
				}
				.font(.system(size: 22))
				.buttonStyle(ActionStyleTrailing())
			)
			.navigationBarTitle(Text("Servers"), displayMode: .inline)
		}
		.sheet(isPresented: $presented, onDismiss: hideSheet, content: {
			if self.sheetType == .createHost {
				NewHostFormModalView(closeHandler: self.hideSheet,
									 root: self.model,
									 hosts: self.model.hostsModel)
			}
			else {
				AboutView(isPresented: self.$presented)
			}
		})
		
	}
	
	func delete(at indexSet: IndexSet) {
		hostsModel.delete(at: indexSet, persistence: model.persistence)
	}
	
	func showSheet() {
		presented = true
	}
	
	func hideSheet() {
		sheetType = .none
		presented = false
	}
	
	func createHost() {
		sheetType = .createHost
		showSheet()
	}
	
	func showAbout() {
		sheetType = .about
		showSheet()
	}
}

#if DEBUG
//struct HostsView_Previews : PreviewProvider {
//	static var previews: some View {
//		NavigationView {
//			HostsView(hosts : HostsModel.sampleModel())
//		}
//	}
//}
#endif

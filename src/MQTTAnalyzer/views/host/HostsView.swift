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

	@State var selectedHost: Host?
	
	var body: some View {
		NavigationView {
			VStack(alignment: .leading) {
				List {
					ForEach(hostsModel.hostsSorted) { host in
						HostCellView(host: host, messageModel: (
							self.model.getMessageModel(host)
							), cloneHostHandler: self.cloneHost)
					}
					.onDelete(perform: self.delete)
					
				}
				if hostsModel.hasDeprecated {
					HStack {
						Image(systemName: "exclamationmark.triangle.fill")
						
						Text("Some of your settings are deprecated and cannot be migrated automatically. Please migrate them from Moscapsule to CocoaMQTT")
					}
					.padding()
					.foregroundColor(.secondary)
					.font(.footnote)
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
				.buttonStyle(ActionStyleL50())
				.accessibility(identifier: "add.server")
			)
			.navigationBarTitle(Text("Servers"), displayMode: .inline)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.selectedHost)
		})
		
	}
	
	func delete(at indexSet: IndexSet) {
		hostsModel.delete(at: indexSet, persistence: model.persistence)
	}
	
	func createHost() {
		sheetType = .createHost
		selectedHost = nil
		presented = true
	}
	
	func cloneHost(host: Host) {
		sheetType = .createHost
		selectedHost = host
		presented = true
	}
	
	func showAbout() {
		sheetType = .about
		presented = true
	}
}

struct HostsViewSheetDelegate: View {
	let model: RootModel
	let hostsModel: HostsModel

	@Binding var presented: Bool
	@Binding var sheetType: HostsSheetType
	
	var selectedHost: Host?
	
	var body: some View {
		Group {
			if self.sheetType == .createHost {
				NewHostFormModalView(closeHandler: { self.presented = false },
									 root: self.model,
									 hosts: self.hostsModel,
									 host: createModel())
			}
			else if self.sheetType == .about {
				AboutView(isPresented: self.$presented)
			}
		}
	}
	
	func createModel() -> HostFormModel {
		if let host = selectedHost {
			return transformHost(source: host)
		}
		else {
			return HostFormModel()
		}
	}
}

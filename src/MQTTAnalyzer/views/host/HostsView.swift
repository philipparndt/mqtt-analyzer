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
	@State var sheetState = ServerPageSheetState()
	@State var searchText: String = ""
	
	@Environment(\.managedObjectContext) private var viewContext

	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \BrokerSetting.alias, ascending: true)],
		animation: .default)
	private var brokers: FetchedResults<BrokerSetting>
	
	var body: some View {
		buildView()
	}
	
	func buildView() -> some View {
		let view = NavigationView {
			VStack(alignment: .leading) {
				List {
					ForEach(searchBroker) { broker in
						HostCellView(host: model.getConnectionModel(broker: broker),
									 hostsModel: hostsModel,
									 messageModel: (
										self.model.getMessageModel(model.getConnectionModel(broker: broker))
									 ),
									 cloneHostHandler: self.cloneHost)
							.accessibilityLabel("broker: \(broker.aliasOrHost)")
					}
				}.searchable(text: $searchText)
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle("Brokers")
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarLeading) {
					Button(action: showAbout) {
						Text("About")
					}
				}
				
				ToolbarItemGroup(placement: .navigationBarTrailing) {
					Button(action: createHost) {
						Image(systemName: "plus")
					}.accessibility(label: Text("Add Broker"))
				}
			}
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
		
		#if targetEnvironment(macCatalyst)
		return view
		#else
		return view.navigationViewStyle(StackNavigationViewStyle())
		#endif
	}
	
	var searchBroker: [BrokerSetting] {
		let sorted = brokers.sorted {
			$0.aliasOrHost > $1.aliasOrHost
		}
		
		if searchText.isEmpty {
			return sorted
		} else {
			let searchFor = searchText.lowercased()
			return sorted.filter { $0.aliasOrHost.lowercased().contains(searchFor) }
		}
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
	
	@Binding var selectedHost: Host?
	
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

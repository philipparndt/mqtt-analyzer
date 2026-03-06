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

	@Binding var selectedBroker: BrokerSetting?

	@Environment(\.managedObjectContext) private var viewContext

	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \BrokerSetting.alias, ascending: true)],
		animation: .default)
	private var brokers: FetchedResults<BrokerSetting>

	var categorizedBrokers: [String: [BrokerSetting]] {
		Dictionary(grouping: searchBroker) { broker in
			broker.category?.isEmpty == true ? "Uncategorized" : (broker.category ?? "Uncategorized")
		}
	}

	var body: some View {
		buildView()
	}

	func buildView() -> some View {
		List(selection: $selectedBroker) {
			if let uncategorizedBrokers = categorizedBrokers["Uncategorized"] {
				ForEach(uncategorizedBrokers, id: \.self) { broker in
					HostCellView(host: model.getConnectionModel(broker: broker),
								 hostsModel: hostsModel,
								 messageModel: (
									self.model.getMessageModel(model.getConnectionModel(broker: broker))
								 ),
								 cloneHostHandler: self.cloneHost,
								 isSelected: selectedBroker == broker)
						.accessibilityLabel("broker: \(broker.aliasOrHost)")
						.tag(broker)
				}
			}

			ForEach(categorizedBrokers.keys.sorted().filter { $0 != "Uncategorized" }, id: \.self) { category in
				Section(header: VStack(alignment: .leading, spacing: 4) {
					Text(category)
					Divider()
				}) {
					ForEach(categorizedBrokers[category] ?? [], id: \.self) { broker in
						HostCellView(host: model.getConnectionModel(broker: broker),
									 hostsModel: hostsModel,
									 messageModel: (
										self.model.getMessageModel(model.getConnectionModel(broker: broker))
									 ),
									 cloneHostHandler: self.cloneHost,
									 isSelected: selectedBroker == broker)
							.accessibilityLabel("broker: \(broker.aliasOrHost)")
							.tag(broker)
					}
				}
			}
		}
		.listStyle(.sidebar)
		.scrollContentBackground(.hidden)
		#if os(iOS)
		.background(.ultraThinMaterial)
		.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
		.toolbarBackgroundVisibility(.visible, for: .navigationBar)
		#elseif os(macOS)
		.background(.clear)
		#endif
		.searchable(text: $searchText, placement: .sidebar)
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle("Brokers")
		#elseif os(macOS)
		.toolbar(removing: .title)
		#endif
		.toolbar {
			#if os(iOS)
			ToolbarItem(placement: .cancellationAction) {
				Button(action: showAbout) {
					Image(systemName: "info.circle")
				}
				.accessibilityLabel("About")
			}
			#endif

			ToolbarItem(placement: .primaryAction) {
				Button(action: createHost) {
					Image(systemName: "plus")
				}
				.accessibilityLabel("Add Broker")
			}
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
	}
	
	var searchBroker: [BrokerSetting] {
		let sorted = brokers.sorted {
			$0.aliasOrHost.lowercased() < $1.aliasOrHost.lowercased()
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

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
	@State var searchText: String = ""

	@Binding var selectedBroker: BrokerSetting?

	#if os(iOS)
	@State private var isEditing = false
	@State private var editSelection = Set<BrokerSetting>()
	@State private var showMoveToCategory = false
	@State private var showDeleteConfirmation = false
	@State private var brokersToMove: [BrokerSetting] = []
	#elseif os(macOS)
	@State private var macSelection = Set<BrokerSetting>()
	@State private var showMoveToCategory = false
	@State private var showDeleteConfirmation = false
	@State private var brokersToMove: [BrokerSetting] = []
	#endif

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
		#if os(iOS)
		ZStack(alignment: .bottom) {
			Group {
				if isEditing {
					List(selection: $editSelection) {
						brokerListContent
					}
					.environment(\.editMode, .constant(.active))
				} else {
					List(selection: $selectedBroker) {
						brokerListContent
					}
				}
			}
			.listStyle(.sidebar)
			.scrollContentBackground(.hidden)
			.background(.ultraThinMaterial)
			.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
			.toolbarBackgroundVisibility(.visible, for: .navigationBar)
			.searchable(text: $searchText, placement: .sidebar)
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle("Brokers")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(action: showAbout) {
						Image(systemName: "info.circle")
					}
					.accessibilityLabel("About")
				}

				ToolbarItem(placement: .primaryAction) {
					Button(action: toggleEditMode) {
						Text(isEditing ? "Done" : "Edit")
					}
					.accessibilityIdentifier("edit-broker-list")
				}
			}

			if isEditing && !editSelection.isEmpty {
				editToolbar
			}

			if !isEditing {
				floatingAddButton
			}
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
		.sheet(isPresented: $showMoveToCategory) {
			MoveToCategoryView(
				brokers: brokersToMove,
				allCategories: existingCategories
			) {
				editSelection.removeAll()
				brokersToMove.removeAll()
				isEditing = false
			}
		}
		.alert(
			"Delete \(editSelection.count) broker\(editSelection.count == 1 ? "" : "s")?",
			isPresented: $showDeleteConfirmation
		) {
			Button("Delete", role: .destructive, action: deleteSelectedBrokers)
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("This action cannot be undone.")
		}
		#else
		List(selection: $macSelection) {
			brokerListContent
		}
		.listStyle(.sidebar)
		.scrollContentBackground(.hidden)
		.background(.clear)
		.searchable(text: $searchText, placement: .sidebar)
		.toolbar(removing: .title)
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button(action: createHost) {
					Image(systemName: "plus")
				}
				.accessibilityLabel("Add Broker")
			}
		}
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Button(action: {
					brokersToMove = Array(macSelection)
					showMoveToCategory = true
				}) {
					Label("Move to Category", systemImage: "folder")
				}
				.disabled(macSelection.isEmpty)
				.help("Move selected brokers to a category")
			}

			ToolbarItem(placement: .automatic) {
				Button(action: { showDeleteConfirmation = true }) {
					Label("Delete", systemImage: "trash")
				}
				.disabled(macSelection.isEmpty)
				.help("Delete selected brokers")
			}
		}
		.onChange(of: macSelection) {
			if macSelection.count == 1 {
				selectedBroker = macSelection.first
			} else if macSelection.isEmpty {
				selectedBroker = nil
			}
		}
		.onDeleteCommand {
			if !macSelection.isEmpty {
				showDeleteConfirmation = true
			}
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
		.sheet(isPresented: $showMoveToCategory) {
			MoveToCategoryView(
				brokers: brokersToMove,
				allCategories: existingCategories
			) {
				macSelection.removeAll()
				brokersToMove.removeAll()
			}
		}
		.alert(
			"Delete \(macSelection.count) broker\(macSelection.count == 1 ? "" : "s")?",
			isPresented: $showDeleteConfirmation
		) {
			Button("Delete", role: .destructive, action: deleteMacSelectedBrokers)
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("This action cannot be undone.")
		}
		#endif
	}

	#if os(iOS)
	private var editToolbar: some View {
		HStack(spacing: 20) {
			Button(action: {
				brokersToMove = Array(editSelection)
				showMoveToCategory = true
			}) {
				Label("Move", systemImage: "folder")
			}

			Spacer()

			Text("\(editSelection.count) selected")
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Spacer()

			Button(role: .destructive, action: { showDeleteConfirmation = true }) {
				Label("Delete", systemImage: "trash")
			}
		}
		.padding(.horizontal, 20)
		.padding(.vertical, 12)
		.background(.ultraThinMaterial)
	}

	private var floatingAddButton: some View {
		HStack {
			Spacer()
			Button(action: createHost) {
				Image(systemName: "plus")
					.font(.title2.weight(.semibold))
					.foregroundColor(.white)
					.frame(width: 56, height: 56)
					.background(Color.accentColor)
					.clipShape(Circle())
					.shadow(radius: 4, y: 2)
			}
			.accessibilityLabel("Add Broker")
			.padding(.trailing, 20)
			.padding(.bottom, 20)
		}
	}

	private func toggleEditMode() {
		withAnimation {
			isEditing.toggle()
			if !isEditing {
				editSelection.removeAll()
			}
		}
	}
	#endif

	@ViewBuilder
	private var brokerListContent: some View {
		if let uncategorizedBrokers = categorizedBrokers["Uncategorized"] {
			ForEach(uncategorizedBrokers, id: \.self) { broker in
				HostCellView(host: model.getConnectionModel(broker: broker),
							 hostsModel: hostsModel,
							 messageModel: (
								self.model.getMessageModel(model.getConnectionModel(broker: broker))
							 ),
							 cloneHostHandler: self.cloneHost,
							 isSelected: selectedBroker == broker)
					.accessibilityIdentifier("broker: \(broker.aliasOrHost)")
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
						.accessibilityIdentifier("broker: \(broker.aliasOrHost)")
						.tag(broker)
				}
			}
		}
	}

	private var existingCategories: [String] {
		let categories = brokers.compactMap { $0.category }
			.filter { !$0.isEmpty }
		return Array(Set(categories)).sorted()
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
		
	#if os(iOS)
	func deleteSelectedBrokers() {
		for broker in editSelection {
			viewContext.delete(broker)
		}
		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		editSelection.removeAll()
		isEditing = false
	}
	#elseif os(macOS)
	func deleteMacSelectedBrokers() {
		for broker in macSelection {
			viewContext.delete(broker)
		}
		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		macSelection.removeAll()
		selectedBroker = nil
	}
	#endif

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

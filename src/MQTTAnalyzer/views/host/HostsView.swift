//
//  HostsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

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

	@State private var showImportPicker = false
	@State private var importAlertMessage: String?
	@State private var showImportAlert = false
	@State private var showExportOptions = false

	@Environment(\.managedObjectContext) private var viewContext

	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \BrokerSetting.alias, ascending: true)],
		animation: .default)
	private var brokers: FetchedResults<BrokerSetting>

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
					if isEditing {
						Button {
							showExportOptions = true
						} label: {
							Image(systemName: "square.and.arrow.up")
						}
						.disabled(editSelection.isEmpty)
						.accessibilityLabel("Export")
					} else {
						Button(action: showAbout) {
							Image(systemName: "info.circle")
						}
						.accessibilityLabel("About")
					}
				}

				ToolbarItem(placement: .primaryAction) {
					if isEditing {
						Button(action: toggleEditMode) {
							Text("Done")
						}
						.accessibilityIdentifier("edit-broker-list")
					} else {
						Menu {
							Button {
								showImportPicker = true
							} label: {
								Label("Import", systemImage: "square.and.arrow.down")
							}
							Button(action: toggleEditMode) {
								Label("Edit", systemImage: "pencil")
							}
							Button(action: createHost) {
								Label("Add Broker", systemImage: "plus")
							}
						} label: {
							Image(systemName: "line.3.horizontal")
						}
						.accessibilityIdentifier("edit-broker-list")
					}
				}
			}

			if isEditing && !editSelection.isEmpty {
				editToolbar
			}
		}
		.fileImporter(
			isPresented: $showImportPicker,
			allowedContentTypes: [.mqttBroker],
			allowsMultipleSelection: false
		) { result in
			handleImportResult(result)
		}
		.alert("Import", isPresented: $showImportAlert) {
			Button("OK") {}
		} message: {
			Text(importAlertMessage ?? "")
		}
		.confirmationDialog(
			"Export \(editSelection.count) Broker\(editSelection.count == 1 ? "" : "s")",
			isPresented: $showExportOptions,
			titleVisibility: .visible
		) {
			Button("Include Secrets") {
				performIOSExport(includeSecrets: true)
			}
			Button("Without Secrets") {
				performIOSExport(includeSecrets: false)
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Include passwords and certificates in the export files?")
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented = false }, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
		.sheet(isPresented: $showMoveToCategory, content: {
			MoveToCategoryView(
				brokers: brokersToMove,
				allCategories: existingCategories,
				onComplete: {
					editSelection.removeAll()
					brokersToMove.removeAll()
					isEditing = false
				}
			)
		})
		.alert(
			"Delete \(editSelection.count) broker\(editSelection.count == 1 ? "" : "s")?",
			isPresented: $showDeleteConfirmation,
			actions: {
				Button("Delete", role: .destructive, action: deleteSelectedBrokers)
				Button("Cancel", role: .cancel) {}
			}, message: {
				Text("This action cannot be undone.")
			}
		)
		#else
		List(selection: $macSelection) {
			brokerListContent
		}
		.listStyle(.sidebar)
		.scrollContentBackground(.hidden)
		.background(.clear)
		.searchable(text: $searchText, placement: .sidebar)
		.navigationTitle("Brokers")
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				Button(action: createHost) {
					Image(systemName: "plus")
				}
				.accessibilityLabel("Add Broker")
				.help("Add a new broker")
			}
		}
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Button {
					brokersToMove = Array(macSelection)
					showMoveToCategory = true
				} label: {
					Label("Move to Category", systemImage: "folder")
				}
				.disabled(macSelection.isEmpty)
				.help("Move selected brokers to a category")
			}

			ToolbarItem(placement: .automatic) {
				Button {
					showDeleteConfirmation = true
				} label: {
					Label("Delete", systemImage: "trash")
				}
				.disabled(macSelection.isEmpty)
				.help("Delete selected brokers")
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .menuNewBroker)) { _ in
			createHost()
		}
		.onReceive(NotificationCenter.default.publisher(for: .menuImportBroker)) { _ in
			showImportPicker = true
		}
		.onReceive(NotificationCenter.default.publisher(for: .menuExportBroker)) { _ in
			if !macSelection.isEmpty {
				showExportOptions = true
			}
		}
		.fileImporter(
			isPresented: $showImportPicker,
			allowedContentTypes: [.mqttBroker],
			allowsMultipleSelection: false
		) { result in
			handleImportResult(result)
		}
		.alert("Import", isPresented: $showImportAlert) {
			Button("OK") {}
		} message: {
			Text(importAlertMessage ?? "")
		}
		.confirmationDialog(
			"Export \(macSelection.count) Broker\(macSelection.count == 1 ? "" : "s")",
			isPresented: $showExportOptions,
			titleVisibility: .visible
		) {
			Button("Include Secrets") {
				performMacExport(includeSecrets: true)
			}
			Button("Without Secrets") {
				performMacExport(includeSecrets: false)
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Include passwords and certificates in the export files?")
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
		.sheet(isPresented: $presented, onDismiss: { self.presented = false }, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType,
								   selectedHost: self.$selectedHost)
		})
		.sheet(isPresented: $showMoveToCategory, content: {
			MoveToCategoryView(
				brokers: brokersToMove,
				allCategories: existingCategories,
				onComplete: {
					macSelection.removeAll()
					brokersToMove.removeAll()
				}
			)
		})
		.alert(
			"Delete \(macSelection.count) broker\(macSelection.count == 1 ? "" : "s")?",
			isPresented: $showDeleteConfirmation,
			actions: {
				Button("Delete", role: .destructive, action: deleteMacSelectedBrokers)
				Button("Cancel", role: .cancel) {}
			}, message: {
				Text("This action cannot be undone.")
			}
		)
		#endif
	}

}

// MARK: - View Helpers

extension HostsView {
	var categorizedBrokers: [String: [BrokerSetting]] {
		Dictionary(grouping: searchBroker) { broker in
			broker.category?.isEmpty == true ? "Uncategorized" : (broker.category ?? "Uncategorized")
		}
	}

	#if os(iOS)
	var editToolbar: some View {
		HStack(spacing: 20) {
			Button {
				brokersToMove = Array(editSelection)
				showMoveToCategory = true
			} label: {
				Label("Move", systemImage: "folder")
			}

			Spacer()

			Text("\(editSelection.count) selected")
				.font(.subheadline)
				.foregroundStyle(.secondary)

			Spacer()

			Button(role: .destructive) {
				showDeleteConfirmation = true
			} label: {
				Label("Delete", systemImage: "trash")
			}
		}
		.padding(.horizontal, 20)
		.padding(.vertical, 12)
		.background(.ultraThinMaterial)
	}

	func toggleEditMode() {
		withAnimation {
			isEditing.toggle()
			if !isEditing {
				editSelection.removeAll()
			}
		}
	}
	#endif

	@ViewBuilder
	var brokerListContent: some View {
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
			#if os(iOS)
			.onDelete { offsets in
				deleteBrokers(offsets, from: uncategorizedBrokers)
			}
			#endif
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
				#if os(iOS)
				.onDelete { offsets in
					deleteBrokers(offsets, from: categorizedBrokers[category] ?? [])
				}
				#endif
			}
		}

		#if os(iOS)
		Section {
			Spacer()
				.frame(height: 60)
				.listRowBackground(Color.clear)
		}
		.listSectionSeparator(.hidden)
		#endif
	}

	var existingCategories: [String] {
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
}

// MARK: - Actions

extension HostsView {
	func deleteBrokers(_ offsets: IndexSet, from brokers: [BrokerSetting]) {
		for index in offsets {
			viewContext.delete(brokers[index])
		}
		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}

	#if os(iOS)
	func performIOSExport(includeSecrets: Bool) {
		let brokersToExport = Array(editSelection)
		guard !brokersToExport.isEmpty else { return }

		var exportedURLs: [URL] = []
		for broker in brokersToExport {
			do {
				let url = try BrokerImportExport.exportBroker(broker, includeSecrets: includeSecrets)
				exportedURLs.append(url)
			} catch {
				NSLog("Failed to export broker '\(broker.aliasOrHost)': \(error)")
			}
		}

		guard !exportedURLs.isEmpty else { return }

		let activityVC = UIActivityViewController(activityItems: exportedURLs, applicationActivities: nil)
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let rootVC = windowScene.windows.first?.rootViewController {
			if let popover = activityVC.popoverPresentationController {
				popover.sourceView = rootVC.view
				popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
				popover.permittedArrowDirections = []
			}
			rootVC.present(activityVC, animated: true)
		}
	}

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

	func performMacExport(includeSecrets: Bool) {
		let brokersToExport = Array(macSelection)
		guard !brokersToExport.isEmpty else { return }

		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.canCreateDirectories = true
		panel.prompt = "Export Here"
		panel.message = "Choose a folder to export \(brokersToExport.count) broker\(brokersToExport.count == 1 ? "" : "s")"

		panel.begin { response in
			guard response == .OK, let directory = panel.url else { return }

			var exported = 0
			for broker in brokersToExport {
				do {
					let tempURL = try BrokerImportExport.exportBroker(broker, includeSecrets: includeSecrets)
					let destination = directory.appendingPathComponent(tempURL.lastPathComponent)
					if FileManager.default.fileExists(atPath: destination.path) {
						try FileManager.default.removeItem(at: destination)
					}
					try FileManager.default.copyItem(at: tempURL, to: destination)
					exported += 1
				} catch {
					NSLog("Failed to export broker '\(broker.aliasOrHost)': \(error)")
				}
			}

			DispatchQueue.main.async {
				importAlertMessage = "Exported \(exported) broker\(exported == 1 ? "" : "s") successfully."
				showImportAlert = true
			}
		}
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

	func handleImportResult(_ result: Result<[URL], Error>) {
		switch result {
		case .success(let urls):
			guard let url = urls.first else { return }
			do {
				let broker = try BrokerImportExport.importBroker(from: url, context: viewContext)
				importAlertMessage = "Broker '\(broker.aliasOrHost)' was imported successfully."
				showImportAlert = true
			} catch {
				importAlertMessage = "Failed to import broker: \(error.localizedDescription)"
				showImportAlert = true
			}
		case .failure(let error):
			importAlertMessage = "Failed to open file: \(error.localizedDescription)"
			showImportAlert = true
		}
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

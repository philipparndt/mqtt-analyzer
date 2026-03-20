//
//  MoveToCategoryView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-19.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MoveToCategoryView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@Environment(\.dismiss) private var dismiss

	let brokers: [BrokerSetting]
	let allCategories: [String]
	var onComplete: () -> Void

	@State private var newCategory = ""

	var body: some View {
		NavigationStack {
			List {
				Section {
					Button(action: { moveToCategory("") }, label: {
						Label("Uncategorized", systemImage: "tray")
					})
				}

				if !allCategories.isEmpty {
					Section(header: Text("Existing Categories")) {
						ForEach(allCategories, id: \.self) { category in
							Button(action: { moveToCategory(category) }, label: {
								Label(category, systemImage: "folder")
							})
						}
					}
				}

				Section(header: Text("New Category")) {
					HStack {
						TextField("Category name", text: $newCategory)
							.disableAutocorrection(true)
							#if os(iOS)
							.textInputAutocapitalization(.never)
							#endif

						Button(action: { moveToCategory(newCategory) }, label: {
							Text("Move")
						})
						.disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
					}
				}
			}
			.navigationTitle("Move to Category")
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
			}
			#if os(macOS)
			.frame(minWidth: 300, minHeight: 300)
			#endif
		}
	}

	private func moveToCategory(_ category: String) {
		for broker in brokers {
			broker.category = category
		}
		do {
			try viewContext.save()
		} catch {
			let nsError = error as NSError
			NSLog("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		onComplete()
		dismiss()
	}
}

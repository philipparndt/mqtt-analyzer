//
//  BrokerView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 11.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct BrokerView: View {
	@Environment(\.managedObjectContext) private var viewContext

	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \BrokerSetting.alias, ascending: true)],
		animation: .default)
	private var brokers: FetchedResults<BrokerSetting>

	var body: some View {
		Group {
			List {
				ForEach(brokers) { broker in
					VStack(alignment: .leading) {
						Text(broker.aliasOrHost)
						Text(broker.id?.uuidString ?? "").font(.footnote)
					}
				}
				.onDelete(perform: delete)
			}
		}
		.navigationTitle("Brokers")
		.toolbar(content: {createToolbar()})
    }
	
	@ToolbarContentBuilder
	func createToolbar() -> some ToolbarContent {
		ToolbarItemGroup(placement: .navigationBarTrailing) {
			Button(action: addBroker) {
			   Image(systemName: "plus")
			}
		}
	}
	
	private func delete(offsets: IndexSet) {
		withAnimation {
			offsets.map { brokers[$0] }.forEach(viewContext.delete)

			do {
				try viewContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
	
	func addBroker() {
		withAnimation {
			let broker = BrokerSetting(context: viewContext)
			broker.id = UUID()
			broker.alias = "some alias"
						
			do {
				try viewContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nsError = error as NSError
				fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
			}
		}
	}
}

struct BrokerView_Previews: PreviewProvider {
    static var previews: some View {
        BrokerView()
    }
}

//
//  NewHostFormView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-25.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct EditHostFormView: View {
	var onDelete: () -> Void
	@Binding var host: HostFormModel
	@State var advanced = false
	@State var confirmDelete = false
	
	var body: some View {
		Form {
			ServerFormView(host: $host)
			AuthFormView(host: $host)
			TopicsFormView(host: $host)
			
			Toggle(isOn: $advanced) {
				Text("More settings")
					.font(.headline)
			}

			if self.advanced {
				CategoryFormView(host: $host)
				ClientIDFormView(host: $host)
				LimitsFormView(host: $host)
			}
			
			Section(header: Text("")) {
				Button(action: delete) {
					HStack(alignment: .center) {
						Spacer()
						Text("Delete")
						Spacer()
					}
				}
				.accessibilityLabel("delete-broker")
				.foregroundColor(.red)
				.font(.body)
				.confirmationDialog("Are you shure you want to delete the broker setting?", isPresented: $confirmDelete, actions: {
					Button("Delete", role: .destructive) {
						deleteNow()
					}
				})
			}
		}
	}
	
	func delete() {
		confirmDelete = true
	}
	
	func deleteNow() {
		onDelete()
	}
}

struct FormFieldInvalidMark: View {
	var invalid: Bool
	
	var body: some View {
		Group {
			if invalid {
				Image(systemName: "xmark.octagon.fill")
				.font(.headline)
					.foregroundColor(.red)
			}
		}
	}
}

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
	@State private var showCertificateHelp = false
	@State private var showDiagnostics = false
	@State private var selectedSubscription: TopicSubscriptionFormModel?
	@State private var isNavigatingToSubscription = false

	var body: some View {
		Form {
			ServerFormView(host: $host)
			TLSFormView(host: $host)
			AuthFormView(host: $host, showCertificateHelp: $showCertificateHelp)
			TopicsFormView(
				host: $host,
				selectedSubscription: $selectedSubscription,
				isNavigatingToSubscription: $isNavigatingToSubscription
			)

			Toggle(isOn: $advanced) {
				Text("More settings")
					.font(.headline)
			}

			if self.advanced {
				CategoryFormView(host: $host)
				ClientIDFormView(host: $host)
				LimitsFormView(host: $host)
			}

			Section {
				Button {
					showDiagnostics = true
				} label: {
					HStack(alignment: .center) {
						Spacer()
						Image(systemName: "stethoscope")
						Text("Test Connection")
						Spacer()
					}
				}
				.foregroundColor(.orange)
				.font(.body)
				.disabled(
					HostFormValidator.validateHostname(name: host.hostname) == nil
					|| HostFormValidator.validatePort(port: host.port) == nil
				)
			}

			Section(header: Text("")) {
				Button {
					delete()
				} label: {
					HStack(alignment: .center) {
						Spacer()
						Text("Delete")
						Spacer()
					}
				}
				.accessibilityLabel("delete-broker")
				.foregroundColor(.red)
				.font(.body)
				.confirmationDialog("Are you shure you want to delete the broker setting?", isPresented: $confirmDelete) {
					Button("Delete", role: .destructive) {
						deleteNow()
					}
				}
			}
		}
		.formStyle(.grouped)
		.sheet(isPresented: $showCertificateHelp) {
			CertificateHelpSheet()
		}
		.sheet(isPresented: $showDiagnostics) {
			DiagnosticsView(
				hostname: host.hostname,
				port: Int(host.port) ?? 1883,
				ssl: host.ssl,
				untrustedSSL: host.untrustedSSL,
				isPresented: $showDiagnostics
			)
		}
		.navigationDestination(isPresented: $isNavigatingToSubscription) {
			if let subscription = selectedSubscription {
				SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)
			}
		}
	}

	func deleteSubscription(subscription: TopicSubscriptionFormModel) {
		host.subscriptions = host.subscriptions.filter { $0.id != subscription.id }
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

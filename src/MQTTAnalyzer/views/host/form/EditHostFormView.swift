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

	private var disableDiagnostics: Bool {
		HostFormValidator.validateHostname(name: host.hostname) == nil
		|| HostFormValidator.validatePort(port: host.port) == nil
	}

	var body: some View {
		#if os(iOS)
		ZStack(alignment: .bottom) {
			formContent
			floatingDiagnosticsButton
		}
		#else
		formContent
		#endif
	}

	private var formContent: some View {
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

			#if !os(macOS)
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

			Section {
				Spacer()
					.frame(height: 60)
					.listRowBackground(Color.clear)
			}
			.listSectionSeparator(.hidden)
			#endif
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
				protocolMethod: host.protocolMethod,
				isPresented: $showDiagnostics,
				formModel: $host
			)
		}
		.navigationDestination(isPresented: $isNavigatingToSubscription) {
			if let subscription = selectedSubscription {
				SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)
			}
		}
	}

	#if os(iOS)
	private var floatingDiagnosticsButton: some View {
		HStack {
			Spacer()
			Button {
				showDiagnostics = true
			} label: {
				Image(systemName: "stethoscope")
					.font(.body.weight(.semibold))
					.frame(width: 40, height: 40)
					.modifier(GlassCircleModifier(color: .orange))
			}
			.disabled(disableDiagnostics)
			.opacity(disableDiagnostics ? 0.4 : 1.0)
			.accessibilityLabel("Test Connection")
			.padding(.trailing, 40)
		}
		.padding(.bottom, 16)
	}
	#endif

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

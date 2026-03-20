//
//  NewHostFormView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-25.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

enum SaveDiagnosticPhase {
	case idle
	case running
	case success
	case failed
	case findings
}

struct EditHostFormView: View {
	var onDelete: () -> Void
	var onCancelDiagnostics: (() -> Void)?
	@Binding var host: HostFormModel
	@Binding var saveDiagnosticPhase: SaveDiagnosticPhase
	@Binding var savedDiagnosticRunner: DiagnosticRunner?
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
			if let runner = savedDiagnosticRunner {
				DiagnosticsView(
					runner: runner,
					isPresented: $showDiagnostics,
					formModel: $host
				)
			} else {
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
		}
		.navigationDestination(isPresented: $isNavigatingToSubscription) {
			if let subscription = selectedSubscription {
				SubscriptionDetailsView(subscription: subscription, deletionHandler: deleteSubscription)
			}
			
		}
	}

	#if os(iOS)
	@State private var isSpinning = false
	@State private var arrowBounce = false

	private var diagnosticButtonColor: Color {
		switch saveDiagnosticPhase {
		case .success:
			return .green
		case .idle, .running, .failed, .findings:
			return .orange
		}
	}

	private var diagnosticButtonIcon: String {
		switch saveDiagnosticPhase {
		case .success:
			return "checkmark"
		default:
			return "stethoscope"
		}
	}

	private var pillContent: some View {
		HStack(spacing: 14) {
			if saveDiagnosticPhase == .running {
				Text("Testing connection")
					.font(.body.weight(.semibold))
					.foregroundStyle(.primary)
			} else {
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundStyle(.orange)
				Text("Diagnostic found issues — tap to review")
					.font(.body.weight(.semibold))
					.foregroundStyle(.primary)
			}

			Spacer()

			if saveDiagnosticPhase == .running {
				ZStack {
					Circle()
						.trim(from: 0, to: 0.3)
						.stroke(Color.orange, lineWidth: 6)
						.frame(width: 36, height: 36)
						.rotationEffect(.degrees(isSpinning ? 360 : 0))
						.animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isSpinning)

					Image(systemName: "stop.fill")
						.font(.system(size: 14, weight: .semibold))
						.foregroundColor(.primary)
				}
				.frame(width: 40, height: 40)
			} else {
				Image(systemName: "stethoscope")
					.font(.body.weight(.semibold))
					.foregroundStyle(.primary)
					.frame(width: 40, height: 40)
			}
		}
		.padding(.leading, 20)
		.padding(.trailing, 6)
		.padding(.vertical, 6)
		.background {
			Group {
				if #available(iOS 26.0, *) {
					Capsule()
						.fill(.clear)
						.glassEffect(.regular)
				} else {
					Capsule()
						.fill(.ultraThinMaterial)
						.shadow(radius: 4, y: 2)
				}
			}
		}
		.clipShape(Capsule())
	}

	private var idleButton: some View {
		HStack {
			Spacer()
			Button {
				showDiagnostics = true
			} label: {
				Image(systemName: diagnosticButtonIcon)
					.font(.body.weight(.semibold))
					.frame(width: 40, height: 40)
					.modifier(GlassCircleModifier(color: diagnosticButtonColor))
			}
			.disabled(disableDiagnostics)
			.opacity(disableDiagnostics ? 0.4 : 1.0)
			.accessibilityLabel("Test Connection")
		}
	}

	private var bouncingArrow: some View {
		Image(systemName: "arrow.down")
			.font(.title2.weight(.bold))
			.foregroundStyle(.orange)
			.offset(y: arrowBounce ? 6 : -2)
			.animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: arrowBounce)
			.onAppear { arrowBounce = true }
			.transition(.opacity)
	}

	private var floatingDiagnosticsButton: some View {
		VStack(spacing: 6) {
			if saveDiagnosticPhase == .findings {
				bouncingArrow
			}

			if saveDiagnosticPhase == .running || saveDiagnosticPhase == .failed || saveDiagnosticPhase == .findings {
				Button {
					if saveDiagnosticPhase == .running {
						onCancelDiagnostics?()
					} else {
						showDiagnostics = true
					}
				} label: {
					pillContent
				}
				.buttonStyle(.plain)
				.accessibilityLabel(
					saveDiagnosticPhase == .running ? "Cancel Diagnostic" : "Review Diagnostic Findings"
				)
				.transition(.opacity.combined(with: .move(edge: .bottom)))
			} else {
				idleButton
			}
		}
		.padding(.horizontal, 40)
		.animation(.easeInOut(duration: 0.3), value: saveDiagnosticPhase)
		.padding(.bottom, 16)
		.onChange(of: saveDiagnosticPhase) {
			if saveDiagnosticPhase == .running {
				isSpinning = true
				arrowBounce = false
			} else if saveDiagnosticPhase == .findings || saveDiagnosticPhase == .failed {
				isSpinning = false
			} else {
				isSpinning = false
				arrowBounce = false
			}
		}
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

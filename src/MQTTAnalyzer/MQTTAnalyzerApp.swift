//
//  MQTTAnalyzerApp.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 11.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import SwiftUI

@main
struct MQTTAnalyzerApp: App {
	@StateObject private var persistenceController = PersistenceController.shared
	let root = RootModel()
	@Environment(\.scenePhase) var scenePhase

	static let disableAnimations = CommandLine.arguments.contains("--disable-animations")

	init() {
		#if DEBUG
		if CommandLine.arguments.contains("--ui-testing") {
			#if os(iOS)
			UIView.setAnimationsEnabled(false)
			#endif

			PersistenceController.shared.createStubs()
		}

		if Self.disableAnimations {
			#if os(iOS)
			UIView.setAnimationsEnabled(false)
			#endif
		}
		#endif

		if CommandLine.arguments.contains("--no-welcome") {
			let defaults = UserDefaults.standard
			defaults.set(false, forKey: Welcome.key)
		}

		ModelMigration.migrateToCoreData()
		HostSettingExamples.inititalize()

		CloudDataManager.instance.initDocumentsDirectory()
	}

	#if os(macOS)
	@Environment(\.openWindow) private var openWindow
	#endif

	var body: some Scene {
		WindowGroup {
			if let error = persistenceController.loadError {
				DatabaseErrorView(message: error)
			} else if persistenceController.isLoaded {
				RootView()
					.environment(\.managedObjectContext, persistenceController.container!.viewContext)
					.environmentObject(root)
					.onAppear {
						#if os(iOS)
						if Self.disableAnimations {
							UIApplication.shared.connectedScenes
								.compactMap { $0 as? UIWindowScene }
								.flatMap { $0.windows }
								.forEach { $0.layer.speed = 100 }
						}
						#endif
					}
			} else {
				LoadingView()
			}
		}
		#if os(macOS)
		.defaultSize(width: 1100, height: 700)
		.windowToolbarStyle(.unified(showsTitle: false))
		.commands {
			CommandGroup(replacing: .appInfo) {
				Button("About MQTTAnalyzer") {
					openWindow(id: "about")
				}
			}
		}
		#endif
		.onChange(of: scenePhase) {
			if scenePhase == .active {
				root.cancelBackgroundDisconnect()
				root.reconnect()
			} else if scenePhase == .background {
				root.scheduleBackgroundDisconnect {
					persistenceController.save()
				}
			}
		}

		#if os(macOS)
		Window("About MQTTAnalyzer", id: "about") {
			AboutWindowView()
		}
		.windowResizability(.contentSize)
		.windowStyle(.hiddenTitleBar)
		#endif
	}
}

struct DatabaseErrorView: View {
	let message: String

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "exclamationmark.triangle")
				.font(.system(size: 48))
				.foregroundColor(.orange)

			Text("Database Error")
				.font(.title)

			Text(message)
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)

			Text("Your data has been reset. Brokers synced via iCloud will reappear automatically.")
				.font(.caption)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
		}
	}
}

struct LoadingView: View {
	var body: some View {
		VStack(spacing: 20) {
			Image("About")
				.resizable()
				.frame(width: 80, height: 80)
				.cornerRadius(16)
				.shadow(radius: 10)

			Text("MQTTAnalyzer")
				.font(.title)

			ProgressView()
				.progressViewStyle(CircularProgressViewStyle())

			Text("Loading...")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
	}
}

#if os(macOS)
struct AboutWindowView: View {
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack(spacing: 0) {
			// Fixed header with icon and title
			HStack {
				Image("About")
					.resizable()
					.frame(width: 64, height: 64)
					.cornerRadius(14)
					.shadow(radius: 10)

				VStack(alignment: .leading, spacing: 4) {
					Text("MQTTAnalyzer")
						.font(.title)
						.fontWeight(.semibold)

					Text("[© 2026 Philipp Arndt](https://github.com/philipparndt)")
						.font(.callout)

					Text("Version \(getVersion())")
						.font(.callout)
						.foregroundColor(.secondary)
				}
			}
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(24)

			Divider()

			// Scrollable content
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					Text("""
This project is open source. Contributions are welcome. Feel free to open an issue ticket and discuss new features.

[Source Code](https://github.com/philipparndt/mqtt-analyzer) · [License](https://github.com/philipparndt/mqtt-analyzer/blob/master/LICENSE) · [Issue tracker](https://github.com/philipparndt/mqtt-analyzer/issues)
""")
					.font(.callout)

					Text("Thank you! This project would not be possible without your great work! Thanks for testing, contributing dependencies, features and ideas.")
						.font(.callout)
						.foregroundColor(.secondary)

					Text("**Contributors**")
						.font(.callout)
						.fontWeight(.semibold)

					Text("[Ulrich Frank](https://github.com/UlrichFrank), [Ricardo Pereira](https://github.com/visnaut), [AndreCouture](https://github.com/AndreCouture), [RoSchmi](https://github.com/RoSchmi), [Xploder](https://github.com/Xploder), [Ed Gauthier](https://github.com/edgauthier)")
						.font(.callout)
						.foregroundColor(.secondary)

					Text("**Dependencies**")
						.font(.callout)
						.fontWeight(.semibold)

					Text("[CocoaMQTT](https://github.com/emqx/CocoaMQTT), [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON), [GRDB](https://github.com/groue/GRDB.swift)")
						.font(.callout)
						.foregroundColor(.secondary)
				}
				.padding(24)
			}

			Divider()

			// Fixed footer with close button
			HStack {
				Spacer()
				Button("Close") {
					dismiss()
				}
				.keyboardShortcut(.defaultAction)
			}
			.padding(16)
		}
		.frame(width: 480, height: 504)
	}
}
#endif

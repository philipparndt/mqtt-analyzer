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

	init() {
		#if DEBUG
		if CommandLine.arguments.contains("--ui-testing") {
			UIView.setAnimationsEnabled(false)

			PersistenceController.shared.createStubs()
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

	var body: some Scene {
		WindowGroup {
			if persistenceController.isLoaded {
				RootView()
					.environment(\.managedObjectContext, persistenceController.container!.viewContext)
					.environmentObject(root)
			} else {
				LoadingView()
			}
		}
		.onChange(of: scenePhase) { newPhase in
			if newPhase == .active {
				root.reconnect()
			}
			persistenceController.save()
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

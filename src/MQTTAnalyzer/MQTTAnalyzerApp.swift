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
	let persistenceController = PersistenceController.shared
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
			RootView()
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
				.environmentObject(root)
		}
		.onChange(of: scenePhase) { _ in
			persistenceController.save()
		}
	}
}

//
//  AppDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import UIKit
import CloudKit
import CocoaMQTT

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		#if DEBUG
		if CommandLine.arguments.contains("--ui-testing") {
			UIView.setAnimationsEnabled(false)
		}
		#endif
	
		if CommandLine.arguments.contains("--no-welcome") {
			let defaults = UserDefaults.standard
			defaults.set(false, forKey: Welcome.key)
		}

		application.registerForRemoteNotifications()
		
		CloudDataManager.instance.initDocumentsDirectory()
		
		// Override point for customization after application launch.
		return true
	}
	
	func afterMigration() {
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
		// swiftlint:disable line_length
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
//		self.saveContext()
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

}

//
//  SceneDelegate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-06-30.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var rootModel: RootModel?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

		rootModel = RootModel()
		
		// Use a UIHostingController as window root view controller
		if let windowScene = scene as? UIWindowScene {
			#if targetEnvironment(macCatalyst)
			if CommandLine.arguments.contains("--ui-testing") {
			// Screenshot resolutions: 1280x800 1440x900 2560x1600 2880x1800
				let width = 1280 - 50
				let height = 800 - 50
				windowScene.sizeRestrictions?.minimumSize = CGSize(width: width, height: height)
				windowScene.sizeRestrictions?.maximumSize = CGSize(width: width, height: height)
			}
			#endif
			
			let window = UIWindow(windowScene: windowScene)
			window.rootViewController = UIHostingController(rootView: RootView()
				.environmentObject(rootModel!))
			self.window = window
			window.makeKeyAndVisible()
		}
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		if let model = rootModel {
			model.reconnect()
		}
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.

		// Save changes in the application's managed object context when the application transitions to the background.
//		(UIApplication.shared.delegate as? AppDelegate)?.saveContext()
	}

}

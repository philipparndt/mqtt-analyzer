//
//  RootView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-02.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Highlightr

struct RootView: View {
	@EnvironmentObject var model: RootModel

	@AppStorage(Welcome.key) var welcome: Bool = true

	var body: some View {
		VStack {
			NavigationView {
				BrokerView()
			}
			HostsView(hostsModel: model.hostsModel)
		}
		.sheet(isPresented: $welcome, onDismiss: closeWelcome, content: {
			WelcomeView(closeHandler: closeWelcome)
		})
	}
	
	func closeWelcome() {
		self.welcome = false
	}
}

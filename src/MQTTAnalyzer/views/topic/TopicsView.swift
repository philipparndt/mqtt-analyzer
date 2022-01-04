//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsView: View {
	@EnvironmentObject var rootModel: RootModel
	@ObservedObject var model: MessageModel
	@ObservedObject var host: Host
	
	@State private var publishMessageModel = PublishMessageFormModel()
	@State private var loginData = LoginData()

	var emptyTopicText: String {
		if model.filterText.isEmpty {
			return "no topics available"
		} else {
			return "no topics available using the current filter"
		}
	}
	
	var body: some View {
		List {
			TopicsToolsView(model: self.model)

			Section(header: Text("Topics")) {
				if model.displayTopics.isEmpty {
					Text(emptyTopicText)
						.foregroundColor(.secondary)
				}
				else {
					ForEach(model.displayTopics) { messages in
						TopicCellView(
							messages: messages,
							model: self.model,
							publishMessagePresented: self.$publishMessageModel.isPresented,
							host: self.host,
							selectMessage: self.selectMessage)
					}
				}
			}
		}
		.searchable(text: $model.filterText)

		.sheet(isPresented: $publishMessageModel.isPresented, onDismiss: cancelDialog, content: {
			PublishMessageFormModalView(closeCallback: self.cancelDialog,
										root: self.rootModel,
										host: self.host,
										model: self.$publishMessageModel)
		})
		.listStyle(GroupedListStyle())
		.navigationTitle(host.aliasOrHost)
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {
				Button(action: createTopic) {
					Image(systemName: "paperplane.fill")
				}

				Button(action: pauseConnection) {
					Image(systemName: host.pause ? "play.fill" : "pause.fill")
				}
			}
			
		}
		.navigationBarTitleDisplayMode(.inline)
		.safeAreaInset(edge: .bottom) {
			createToolInset()
		}
		.sheet(isPresented: $loginData.isPresented, onDismiss: cancelDialog, content: {
			LoginDialogView(loginCallback: self.login, host: self.host)
		})
		.onAppear {
			if self.host.needsAuth {
				self.loginData.username = self.host.username
				self.loginData.password = self.host.password
				self.loginData.isPresented = true
			}
			else {
				self.rootModel.connect(to: self.host)
			}
		}
	}

	func createToolInset() -> some View {
		return VStack(spacing: 0) {
			if host.needsAuth {
				LoginView(loginDialogPresented: self.$loginData.isPresented, host: host)
			}
			else if model.topicLimit && !host.pause {
				TopicLimitReachedView()
			}
			else if model.messageLimit && !host.pause {
				MessageLimitReachedView()
			}
			else if host.state == .connected && host.pause {
				ResumeConnectionView(host: host)
			}
			else if host.state == .connecting {
				ConnectingView(host: host)
			}
			else if host.state == .disconnected {
				DisconnectedView(host: host)
			}
		}
		.background(.ultraThinMaterial)
		.controlSize(.large)
	}
	
	func createTopic() {
		self.publishMessageModel = PublishMessageFormModel()
		self.publishMessageModel.isPresented = true
	}

	func pauseConnection() {
		host.pause.toggle()
	}
	
	func cancelDialog() {
		self.publishMessageModel.isPresented = false
		self.loginData.isPresented = false
	}
		
	func login() {
		self.loginData.isPresented = false
		rootModel.connect(to: self.host)
	}
	
	func selectMessage(message: Message) {
		publishMessageModel = of(message: message)
	}

}

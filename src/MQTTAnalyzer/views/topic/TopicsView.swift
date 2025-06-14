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
	@ObservedObject var model: TopicTree
	@ObservedObject var host: Host
	
	@StateObject private var publishMessageModel = PublishMessageFormModel()
	@State private var loginData = LoginData()
	
	var body: some View {
		VStack {
			if model.messageCount == 0 && model.children.keys.isEmpty {
				AwaitMessagesView(model: model, host: host)
				.sheet(isPresented: $publishMessageModel.isPresented, onDismiss: cancelDialog, content: {
					PublishMessageFormModalView(closeCallback: self.cancelDialog,
												root: self.rootModel,
												host: self.host,
												model: publishMessageModel)
				})
			}
			else {
				List {
					if !self.model.filterText.isBlank {
						HStack {
							Text("Matches")
							Spacer()
							Text("\(model.searchResultDisplay.count)")
						}
						
						Toggle("Whole word", isOn: self.$model.filterWholeWord)
							.accessibilityLabel("whole-word")

						Section(header: Text("Search result")) {
							if model.searchResultDisplay.isEmpty {
								HStack(alignment: .top) {
									Image(systemName: "magnifyingglass")
										.font(.largeTitle)
										.foregroundColor(.secondary)
									
									VStack(alignment: .leading) {
										Text("No matches with the current filter")
										Text("")
										
										VStack(alignment: .leading) {
											Text("Did you know, that by default only whole words are matching?" +
												 "You can turn this off or use * as wildcard. With this, it is possible to distinct between 'on' and 'online'.")
												.multilineTextAlignment(.leading)
										}
										.font(.subheadline)
										.foregroundColor(.secondary)
									}
								}
							}
							else {
								ForEach(model.searchResultDisplay) { result in
									TopicCellView(
										messages: result,
										publishMessagePresented: self.$publishMessageModel.isPresented,
										host: self.host,
										selectMessage: self.selectMessage
									)
								}
							}
						}
					}
					else {
						TopicsToolsView(model: self.model)

						Toggle("Flat", isOn: self.$model.flatView)
							.accessibilityLabel("flatview")

						if !self.model.flatView {
							FolderNavigationView(host: host, model: model)
						}
						
						if self.model.flatView {
							Section(header: Text("Messages (flat)")) {
								ForEach(model.recusiveAllMessages) { messages in
									TopicCellView(
										messages: messages,
										publishMessagePresented: self.$publishMessageModel.isPresented,
										host: self.host,
										selectMessage: self.selectMessage
									)
								}
							}
						}
						else if !model.messages.isEmpty {
							Section(header: Text("Message")) {
								TopicCellView(
									messages: self.model,
									publishMessagePresented: self.$publishMessageModel.isPresented,
									host: self.host,
									selectMessage: self.selectMessage
								)
							}
						}
						
						if !self.model.flatView && !model.childrenWithMessages.isEmpty {
							Section(header: Text("Inherited Message Groups")) {
								ForEach(model.childrenWithMessages) { messages in
									TopicCellView(
										messages: messages,
										publishMessagePresented: self.$publishMessageModel.isPresented,
										host: self.host,
										selectMessage: self.selectMessage
									)
								}
							}
						}
					}
				}
				.searchable(text: $model.filterText)
				.disableAutocorrection(true)
				.sheet(isPresented: $publishMessageModel.isPresented, onDismiss: cancelDialog, content: {
					PublishMessageFormModalView(closeCallback: self.cancelDialog,
												root: self.rootModel,
												host: self.host,
												model: publishMessageModel)
				})
				.listStyle(GroupedListStyle())
			}

		}
		.navigationTitle(title())
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {

				Button(action: createTopic) {
					Image(systemName: "paperplane.fill")
				}
				#if !targetEnvironment(macCatalyst)
				Button(action: model.markRead) {
					Image(systemName: "circle")
					.font(.subheadline)
					.foregroundColor(.blue)
				}
				#endif
				Button(action: pauseConnection) {
					Image(systemName: host.pause ? "play.fill" : "pause.fill")
				}.frame(width: 25, alignment: .leading)
			}
			#if targetEnvironment(macCatalyst)
			ToolbarItemGroup(placement: .navigationBarLeading) {
				Button(action: model.markRead) {
					Image(systemName: "circle")
					.font(.subheadline)
					.foregroundColor(.blue)
				}
				.accessibilityLabel("Mark all as read")
				
				Button(action: model.clear) {
					Image(systemName: "clear")
					.font(.subheadline)
					.foregroundColor(.red)
				}
				.accessibilityLabel("Clear")
			}
			#endif
		}
		.navigationBarTitleDisplayMode(.inline)
		.safeAreaInset(edge: .bottom) {
			createToolInset()
		}
		.sheet(isPresented: $loginData.isPresented, onDismiss: cancelDialog, content: {
			LoginDialogView(loginCallback: self.login, host: self.host)
		})
		.onAppear {
			#if !targetEnvironment(macCatalyst)
			if self.host.needsAuth {
				self.loginData.username = self.host.settings.username ?? ""
				self.loginData.password = self.host.settings.password ?? ""
				self.loginData.isPresented = true
			}
			else {
				self.rootModel.connect(to: self.host)
			}
			#endif
		}
	}

	func title() -> String {
		if model.parent != nil {
			return model.name
		}
		else {
			return host.settings.aliasOrHost
		}
	}
	
	func connect() {
		self.rootModel.connect(to: self.host)
	}
	
	func createToolInset() -> some View {
		return VStack(spacing: 0) {
			if host.needsAuth {
				LoginView(loginDialogPresented: self.$loginData.isPresented, host: host)
			}
			else if model.topicLimitExceeded && !host.pause {
				TopicLimitReachedView()
			}
			else if model.messageLimitExceeded && !host.pause {
				MessageLimitReachedView()
			}
			else if host.state == .connected && host.pause {
				ResumeConnectionView(host: host)
			}
			else if host.state == .connecting {
				ConnectingView(host: host)
			}
			else if host.state == .disconnected {
				if host.reconnectDelegate != nil {
					DisconnectedView(host: host)
				}
				else {
					ConnectBrokerView(connect: connect)
				}
			}
		}
		.background(.ultraThinMaterial)
		.controlSize(.large)
	}
	
	func createTopic() {
		publishMessageModel.topic = model.nameQualified
		publishMessageModel.isPresented = true
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
	
	func selectMessage(message: MsgMessage) {
		publishMessageModel.topic = message.topic.nameQualified
		publishMessageModel.message = message.payload.dataString
		publishMessageModel.qos = Int(message.metadata.qos)
		publishMessageModel.retain = message.metadata.retain
		publishMessageModel.isPresented = true
	}

}

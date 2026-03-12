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
	@State private var limitsSettingsPresented = false
	@State private var limitsSettingsType: LimitType = .topicLimit
	
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
					#if os(iOS)
					if model.parent != nil && !model.nameQualified.isEmpty {
						Section {
							TopicPathView(topic: model.nameQualified)
								.listRowInsets(EdgeInsets())
								.listRowBackground(Color.clear)
								.listRowSeparator(.hidden)
						}
					}
					#endif

					if !self.model.filterText.isBlank {
						HStack {
							Text("Matches")
							Spacer()
							Text("\(model.searchResultDisplay.count)")
						}
						
						Toggle("Whole word", isOn: self.$model.filterWholeWord)
							.accessibilityIdentifier("whole-word")

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
							.accessibilityIdentifier("flatview")

						if !self.model.flatView {
							TreeNavigationView(
								host: host,
								model: model,
								publishMessagePresented: $publishMessageModel.isPresented,
								selectMessage: selectMessage,
								createNewTopic: setTopic
							)
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
				#if os(iOS)
		.listStyle(.insetGrouped)
		#endif
			}

		}
		.navigationTitle(title())
		.toolbar {
			ToolbarItem(placement: .primaryAction) {
				ControlGroup {
					Button(action: createTopic) {
						Label("Send", systemImage: "paperplane.fill")
					}
					.accessibilityIdentifier("Send")

					Button(action: model.markRead) {
						Label("Mark read", systemImage: "circlebadge")
					}

					Button(role: .destructive, action: model.clear) {
						Label("Clear", systemImage: "trash")
					}
				}
			}

			ToolbarItem(placement: .secondaryAction) {
				Button(action: pauseConnection) {
					Label(host.pause ? "Resume" : "Pause", systemImage: host.pause ? "play.fill" : "pause.fill")
				}
			}
		}
		#if !os(macOS)
.navigationBarTitleDisplayMode(.inline)
#endif
		.safeAreaInset(edge: .bottom) {
			createToolInset()
		}
		.sheet(isPresented: $loginData.isPresented, onDismiss: cancelDialog, content: {
			LoginDialogView(loginCallback: self.login, host: self.host)
		})
		.sheet(isPresented: $limitsSettingsPresented) {
			LimitsSettingsDialog(
				host: host,
				model: model,
				limitType: limitsSettingsType,
				onDismiss: { limitsSettingsPresented = false }
			)
		}
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
				TopicLimitReachedView(
					onDismiss: dismissLimitWarning,
					onOpenSettings: { openLimitsSettings(type: .topicLimit) }
				)
			}
			else if model.messageLimitExceeded && !host.pause {
				MessageLimitReachedView(
					onDismiss: dismissLimitWarning,
					onOpenSettings: { openLimitsSettings(type: .messageBatchLimit) }
				)
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

	func setTopic(_ topic: String) {
		publishMessageModel.topic = topic
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
		publishMessageModel.messageType = message.payload.isJSON ? .json : .plain

		// Populate JSON form properties if message is JSON
		if let json = message.payload.jsonData {
			publishMessageModel.jsonData = json
			publishMessageModel.properties = createJsonProperties(json: json, path: [])
				.sorted(by: { $0.pathName < $1.pathName })
		} else {
			publishMessageModel.jsonData = nil
			publishMessageModel.properties = []
		}

		publishMessageModel.isPresented = true
	}

	func dismissLimitWarning() {
		model.topicLimitExceeded = false
		model.messageLimitExceeded = false
	}

	func openLimitsSettings(type: LimitType) {
		limitsSettingsType = type
		limitsSettingsPresented = true
	}

}

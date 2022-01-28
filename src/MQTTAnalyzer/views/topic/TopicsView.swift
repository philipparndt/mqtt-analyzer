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
	
	var path: Topic

	var emptyTopicText: String {
		if model.filterText.isEmpty {
			return "no topics available"
		} else {
			return "no topics available using the current filter"
		}
	}
	
	var body: some View {
		VStack {
			if model.messageCount == 0 {
				AwaitMessagesView(model: model, host: host)
			}
			else {
				List {
					TopicsToolsView(model: self.model)

					HStack {
						Text("Path")
						Spacer()
						Text(path.segments.joined(separator: "/"))
							.textSelection(.enabled)
					}
					
					Section(header: Text("Topics")) {
						if model.displayTopics.isEmpty {
							Text(emptyTopicText)
								.foregroundColor(.secondary)
						}
						else {
							ForEach(model.topicByPath(path)) { subPath in
								NavigationLink(destination: TopicsView(model: self.model, host: self.host, path: subPath)) {
									HStack {
										Image(systemName: "folder.fill")
											.foregroundColor(.blue)
										Text(subPath.name)
										
										Spacer()
										
										Text("\(model.countDisplayTopics(by: subPath))")
									}
								}
							}
							
							ForEach(model.displayTopics(by: path)) { messages in
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
			}

		}
		.navigationTitle(title())
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {

				Button(action: createTopic) {
					Image(systemName: "paperplane.fill")
				}
				#if !targetEnvironment(macCatalyst)
				Button(action: model.readall) {
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
				Button(action: model.readall) {
					Image(systemName: "circle")
					.font(.subheadline)
					.foregroundColor(.blue)
				}
				Button(action: model.clear) {
					Image(systemName: "clear")
					.font(.subheadline)
					.foregroundColor(.red)
				}
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
				self.loginData.username = self.host.username
				self.loginData.password = self.host.password
				self.loginData.isPresented = true
			}
			else {
				self.rootModel.connect(to: self.host)
			}
			#endif
		}
	}

	func title() -> String {
		if path.name.isEmpty {
			return host.aliasOrHost
		}
		else {
			return path.lastSegment
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

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
	
	var body: some View {
		Group {
			ReconnectView(host: self.host, model: self.model, loginDialogPresented: self.$loginData.isPresented)
			.sheet(isPresented: $loginData.isPresented, onDismiss: cancelPublishMessageCreation, content: {
				LoginDialogView(loginCallback: self.login, host: self.host, data: self.$loginData)
			})
			
			List {
				TopicsToolsView(model: self.model)

				Section(header: Text("Topics")) {
					if model.displayTopics.isEmpty {
						Text("no topics available")
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
			.sheet(isPresented: $publishMessageModel.isPresented, onDismiss: cancelPublishMessageCreation, content: {
				PublishMessageFormModalView(closeCallback: self.cancelPublishMessageCreation,
											root: self.rootModel,
											host: self.host,
											model: self.$publishMessageModel)
			})
		}
		.navigationBarTitle(Text(host.aliasOrHost), displayMode: .inline)
		.listStyle(GroupedListStyle())
		.navigationBarItems(
			trailing:
			HStack {
				if host.state == .connected {
					Spacer()
					
					Button(action: createTopic) {
						Image(systemName: "paperplane.fill")
					}
					.font(.system(size: 22))
					.buttonStyle(ActionStyleL25())
					
					Button(action: pauseConnection) {
						Image(systemName: host.pause ? "play.fill" : "pause.fill")
					}
					.frame(minWidth: 50)
					.font(.system(size: 22))
					.buttonStyle(ActionStyleL25())
				
				}
			}
		)
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
	
	func createTopic() {
		self.publishMessageModel = PublishMessageFormModel()
		self.publishMessageModel.isPresented = true
	}

	func pauseConnection() {
		host.pause.toggle()
	}
	
	func cancelPublishMessageCreation() {
		self.publishMessageModel.isPresented = false
	}
		
	func login() {
		rootModel.connect(to: self.host)
	}
	
	func selectMessage(message: Message) {
		publishMessageModel = of(message: message)
	}

}

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
#endif

//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsListView: View {
	@ObservedObject var host: Host
	@ObservedObject var model: MessageModel
	@Binding var dialogPresented: Bool
	@Binding var publishMessageModel: PublishMessageFormModel?
	
	var body: some View {
		Group {
			ReconnectView(host: self.host, model: self.model, loginDialogPresented: self.$dialogPresented)

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
								publishMessagePresented: self.$dialogPresented,
								host: self.host,
								selectMessage: self.selectMessage)
						}
					}
				}
			}
		}
	}
	
	func selectMessage(message: Message) {
		publishMessageModel = PublishMessageFormModel.of(message: message)
	}
}

struct TopicsView: View {
	@EnvironmentObject var rootModel: RootModel
	var model: MessageModel
	@ObservedObject var host: Host
	@State private var actionSheetPresented = false
	@State var dialogPresented: Bool
	@State private var publishMessageModel: PublishMessageFormModel?
	
	var body: some View {
		TopicsListView(
			host: host,
			model: model,
			dialogPresented: $dialogPresented,
			publishMessageModel: $publishMessageModel)
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
			if !self.host.needsAuth {
				self.rootModel.connect(to: self.host)
			}
		}
		.sheet(isPresented: $dialogPresented, onDismiss: cancelPublishMessageCreation, content: {
			if self.host.needsAuth {
				LoginDialogView(loginCallback: self.login, host: self.host, data: self.createLoginDataModel())
			}
			else {
				PublishMessageFormModalView(closeCallback: self.cancelPublishMessageCreation,
										 root: self.rootModel,
										 host: self.host,
										 model: self.publishMessageModel!)
			}
		})
	}
	
	func createLoginDataModel() -> LoginData {
		return LoginData(username: host.username, password: host.password)
	}
	
	func showActionSheet() {
		actionSheetPresented = true
	}
	
	func createTopic() {
		actionSheetPresented = false
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
			self.publishMessageModel = PublishMessageFormModel()
			self.dialogPresented = true
		}
	}

	func pauseConnection() {
		host.pause.toggle()
	}
	
	func cancelPublishMessageCreation() {
		dialogPresented = false
		publishMessageModel = nil
	}
	
	func cancelLogin() {
		dialogPresented = false
	}
	
	func login() {
		dialogPresented = false
		rootModel.connect(to: self.host)
	}
	
	func selectMessage(message: Message) {
		publishMessageModel = PublishMessageFormModel.of(message: message)
	}

}

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//	static var previews: some View {
//		ContentView()
//	}
//}
#endif

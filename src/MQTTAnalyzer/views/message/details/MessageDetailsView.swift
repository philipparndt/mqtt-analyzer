//
//  MessageView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI


struct MessageDetailsView : View {
    let message: Message
    let topic: Topic
    
    var body: some View {
        VStack {
            VStack {
                List {
                    Section(header: Text("Metadata")) {
                        HStack {
                            Text("Topic")
                            Spacer()
                            Text(topic.name)
                        }
                        HStack {
                            Text("Timestamp")
                            Spacer()
                            Text(message.localDate())
                        }
                        HStack {
                            Text("QoS")
                            Spacer()
                            Text("\(message.qos)")
                        }
                    }
                    
                    Section(header: Text("Message")) {
                        if (message.isJson()) {
                            MessageDetailsJsonView(message: JsonFormatString(json: message.prettyJson()))
                        }
                        else {
                            MessageDetailsPlainTextView(message: message)
                        }
                    }
                }
                
            }
        }
    }
}

#if DEBUG
struct MessageDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        MessageDetailsView(message : Message(data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(), qos: 0), topic: Topic("some topic"))
    }
}
#endif

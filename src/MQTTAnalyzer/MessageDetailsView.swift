//
//  MessageView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-24.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI
import Highlightr

struct MessageDetailsView : View {
    let message: Message
    let topic: Topic
    
    var body: some View {
        VStack {
            VStack {
                Form {
                    HStack {
                        Text("Topic")
                        Spacer()
                        Text(topic.name)
                    }
//                    HStack {
//                        Text("Type")
//                        Spacer()
//                        Text(message.isJson() ? "JSON" : "Plain Text")
//                    }
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
                .frame(minWidth: 200, maxWidth: .infinity, minHeight: 0, maxHeight: 200, alignment: .topLeading)
//            Section(header: Text("Metadata")) {
                
//            }
            }.padding()
            VStack {
                if (message.isJson()) {
                    JSONView(message: message.prettyJson())
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
//                    .background(Color.red)
                }
                else {
                    Text(message.data)
                    .lineLimit(nil)
                    .padding(10)
                    .font(.system(.body, design: .monospaced))
                }
                
            }
        }
    }
}

struct JSONView : View {
    let message: String
    
    var body: some View {
        TextWithAttributedString(attributedString: highlightText(json: self.message))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .lineLimit(nil)
        .padding(10)
    }
    
    private func highlightText(json message: String) -> NSAttributedString {
        let highlightr = Highlightr()!
        highlightr.setTheme(to: "paraiso-dark")

        return highlightr.highlight(message, as: "json")!
    }
}

#if DEBUG
struct MessageDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        MessageDetailsView(message : Message(data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(), qos: 0), topic: Topic("some topic"))
    }
}
#endif

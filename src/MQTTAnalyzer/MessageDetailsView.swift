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
                            JSONView(message: JsonFormatString(json: message.prettyJson()))
                        }
                        else {
                            Text(message.data)
                            .lineLimit(nil)
                            .padding(10)
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                
            }.padding()
        }
    }
}

struct JSONView : View {
    let message: JsonFormatString
    
    @State var height : CGFloat = 500
    
    var body: some View {
        VStack {
            AttributedUILabel(attributedString: message.getAttributed(), height: self.$height)
            
            Text("\(height)")
        }
        .frame(height: message.getAttributed().height(withConstrainedWidth: 500), alignment: .top)
    }
}

#if DEBUG
struct MessageDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        MessageDetailsView(message : Message(data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(), qos: 0), topic: Topic("some topic"))
    }
}
#endif

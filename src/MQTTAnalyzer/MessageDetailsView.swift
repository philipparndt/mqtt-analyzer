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
            List {
                Section(header: Text("Metadata")) {
                    HStack {
                        Text("Topic")
                        Spacer()
                        Text(topic.name)
                    }
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(message.isJson() ? "JSON" : "Plain Text")
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
                    VStack {
                        if (message.isJson()) {
                            JSONView(message: message.prettyJson())
                        }
                        else {
                            Text(message.data)
                            .lineLimit(nil)
                            .padding(20)
                            .font(.system(.body, design: .monospaced))
                        }
                        
                    }
                }
            }
        }
    }
}

//struct TextView: UIViewRepresentable {
//    @Binding var text: String
//
//    func makeUIView(context: Context) -> UITextView {
//        return UITextView()
//    }
//
//    func updateUIView(_ uiView: UITextView, context: Context) {
//        uiView.text = text
//    }
//}
//
//struct ContentView : View {
//    @State var text = ""
//
//    var body: some View {
//        TextView(text: $text)
//            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//    }
//}

struct JSONView : View {
    let message: String
    @State private var textViewHeight: CGFloat = 400
    
    var body: some View {
        TextWithAttributedString(textViewHeight: self.$textViewHeight,
                                 attributedString: highlightText(json: self.message))
//        .frame(minWidth: 0, maxWidth: .infinity, minHeight: size(json: self.message), maxHeight: .infinity)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: textViewHeight, maxHeight: .infinity)
//        .frame(height: size(json: self.message))
        .lineLimit(nil)
        .padding(20)
    }
    
    private func highlightText(json message: String) -> NSAttributedString {
        let highlightr = Highlightr()!
        highlightr.setTheme(to: "paraiso-dark")

        return highlightr.highlight(message, as: "json")!
    }
    
//    private func size(json message: String) -> CGFloat {
//        let highlightr = Highlightr()!
//        highlightr.setTheme(to: "paraiso-dark")
//        let string =  highlightr.highlight(message, as: "json")!
//
//        let view = ViewWithLabel(frame:CGRect.zero)
//        view.setString(string)
//        view.scale()
//        print(view.height)
//
//        return view.height * 2
//    }
}

#if DEBUG
struct MessageDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        MessageDetailsView(message : Message(data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date(), qos: 0), topic: Topic("some topic"))
    }
}
#endif

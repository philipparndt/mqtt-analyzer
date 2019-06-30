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
    
    var body: some View {
        VStack {
            Text(message.isJson() ? "JSON" : "Plain Text")
            Text(message.localDate()).padding()
            Text(message.isJson() ? message.prettyJson() : message.data)
                .relativeWidth(100)
                .lineLimit(nil)
                .foregroundColor(Color.gray)
        }
    }
}

#if DEBUG
struct MessageDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        MessageDetailsView(message : Message(data: "{\"temperature\": 56.125, \"longProp\": \"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod\" }", date: Date()))
    }
}
#endif

//
//  AboutView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-03.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

// MARK: Create Host
struct AboutView: View {
    @Binding var isPresented: Bool
	
    var body: some View {
		VStack(alignment: .leading) {
			Group {
				Text("MQTTAnalyzer")
					.font(.title)
				
				LinkButtonView(text: "© 2020 Philipp Arndt", url: "https://github.com/philipparndt")
					.font(.caption)
					.foregroundColor(.secondary)
			}.frame(maxWidth: .infinity, alignment: .center)
			.multilineTextAlignment(.center)
			
			Text("").padding()
			
			Group {
				Text("Open source:")
					.font(.headline)
					.padding()
				
				Group {
					Text("This project is open source. Feel free to contribute enhancements, fixes and issue tickes:")
					
					LinkButtonView(text: "https://github.com/philipparndt/mqtt-analyzer",
								   url: "https://github.com/philipparndt/mqtt-analyzer")
					LinkButtonView(text: "License",
								   url: "https://github.com/philipparndt/mqtt-analyzer/blob/master/LICENSE")
				}.padding(.leading)
			}
			
			Text("")
			
			Group {
				Text("Contributors:")
					.font(.headline)
					.padding()
				
				Group {
					Text("Thanks for testing, contributing features and ideas.")
					
					LinkButtonView(text: "Ulrich Frank",
								   url: "https://github.com/UlrichFrank")
				}.padding(.leading)
			}
			
			Text("")
			
			Group {
				Text("Dependencies:")
					.font(.headline)
					.padding()
			
				Group {
					Text("Thank you! This project would not be possible without your great work!")

					LinkButtonView(text: "Moscapsule", url: "https://github.com/flightonary/Moscapsule")
					LinkButtonView(text: "OpenSSL-Universal", url: "https://github.com/krzyzanowskim/OpenSSL")
					LinkButtonView(text: "RealmSwift", url: "https://realm.io/docs/swift/latest/")
					LinkButtonView(text: "IceCream", url: "https://github.com/caiyue1993/IceCream")
					LinkButtonView(text: "Highlightr", url: "https://github.com/raspu/Highlightr")
					LinkButtonView(text: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON")
					LinkButtonView(text: "swift-petitparser", url: "https://github.com/philipparndt/swift-petitparser")
				}.padding(.leading)
			}
			
			Spacer()
		}
		.padding()
		.frame(maxWidth: .infinity, alignment: .leading)
		.multilineTextAlignment(.leading)
        .navigationBarTitle(Text("About"))
		.navigationBarItems(
			leading: Button(action: close) {
				Text("Close")
			}.buttonStyle(ActionStyleLeading())
		)
    }
    
    func close() {
        self.isPresented = false
    }
}

struct LinkButtonView: View {
	let text: String
	let url: String

	var body: some View {
		Button(action: open) {
			Text(text)
		}
    }
    
    func open() {
		let url: NSURL = URL(string: self.url)! as NSURL
		UIApplication.shared.open(url as URL)
    }
}

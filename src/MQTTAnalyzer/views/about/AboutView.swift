//
//  AboutView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-03.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

func getVersion() -> String {
	if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
		let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
		return "\(marketingVersion).\(buildNumber)"
	}
	else {
		return "no bundle version"
	}
}

// MARK: Create Host
struct AboutView: View {
	@Binding var isPresented: Bool
	
	var body: some View {
		NavigationView {
			VStack(alignment: .leading) {
				AboutTitleView().padding([.top, .bottom])
				Text("""
This project is open source. Contributions are welcome. Feel free to open an issue ticket and discuss new features.
[Source Code](https://github.com/philipparndt/mqtt-analyzer), [License](https://github.com/philipparndt/mqtt-analyzer/blob/master/LICENSE), [Issue tracker](https://github.com/philipparndt/mqtt-analyzer/issues)

Thank you! This project would not be possible without your great work! Thanks for testing, contributing dependencies, features and ideas.

**Contributors**
[Ulrich Frank](https://github.com/UlrichFrank), [Ricardo Pereira](https://github.com/visnaut), [AndreCouture](https://github.com/AndreCouture), [RoSchmi](https://github.com/RoSchmi),
[Xploder](https://github.com/Xploder), [Ed Gauthier](https://github.com/edgauthier)

**Dependencies**
[CocoaMQTT](https://github.com/emqx/CocoaMQTT), [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket), [Starscream](https://github.com/daltoniam/Starscream), [RealmSwift](https://realm.io/docs/swift/latest/), [IceCream](https://github.com/caiyue1993/IceCream), [Highlightr](https://github.com/raspu/Highlightr), [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON), [swift-petitparser](https://github.com/philipparndt/swift-petitparser)

""").foregroundColor(.secondary)
					.font(.footnote)
				Spacer()
			}
			.padding()
			.frame(maxWidth: .infinity, alignment: .leading)
			.multilineTextAlignment(.leading)
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle("About")
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarLeading) {
					Button(action: close) {
						Text("Close")
					}
				}
			}
		}.navigationViewStyle(StackNavigationViewStyle())
	}
	
	func close() {
		self.isPresented = false
	}
}

struct AboutTitleView: View {
	var body: some View {
		Group {
			HStack {
				Image("About")
					.resizable()
					.frame(width: 50.0, height: 50.0)
					.cornerRadius(10)
					.shadow(radius: 10)
					.padding(.trailing)
					.accessibility(identifier: "about.logo")
				
				VStack(alignment: .leading) {
					Text("MQTTAnalyzer")
						.font(.title)
						.accessibilityLabel("about-label")

					Text("[© 2021 Philipp Arndt](https://github.com/philipparndt)")
						.font(.caption)
						.foregroundColor(.blue)
					
					Text(getVersion())
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			
		}
		.frame(maxWidth: .infinity, alignment: .center)
		.multilineTextAlignment(.center)
		.padding([.top, .bottom])
	}
}

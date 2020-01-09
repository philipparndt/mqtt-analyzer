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
		VStack {
			AboutTitleView().padding([.top, .bottom])
			
			ScrollView {
				VStack(alignment: .leading) {
					LicenseView().padding(.bottom)
					ContributorsView().padding(.bottom)
					DependenciesView()
				}
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
				
				VStack(alignment: .leading) {
					Text("MQTTAnalyzer")
						.font(.title)

					LinkButtonView(text: "© 2020 Philipp Arndt", url: "https://github.com/philipparndt")
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

struct LicenseView: View {
	var body: some View {
		Group {
			Text("Open source:")
				.font(.headline)
				.padding(.bottom)
			
			Group {
				Text("This project is open source. Contributions are welcome. Feel free to open an issue ticket and discuss new features:")
				
				LinkButtonView(text: "https://github.com/philipparndt/mqtt-analyzer",
							   url: "https://github.com/philipparndt/mqtt-analyzer")
				
				LinkButtonView(text: "License",
							   url: "https://github.com/philipparndt/mqtt-analyzer/blob/master/LICENSE")
			}
		}
	}
}

struct ContributorsView: View {
	var body: some View {
		Group {
			Text("Contributors:")
				.font(.headline)
				.padding(.bottom)
			
			Group {
				Text("Thanks for testing, contributing features and ideas.")
				
				LinkButtonView(text: "Ulrich Frank",
							   url: "https://github.com/UlrichFrank")
			}
		}
	}
}

struct DependenciesView: View {
	var body: some View {
		Group {
			Text("Dependencies:")
				.font(.headline)
				.padding(.bottom)
		
			Group {
				Text("Thank you! This project would not be possible without your great work!")
				
				LinkButtonView(text: "Moscapsule", url: "https://github.com/flightonary/Moscapsule")
				LinkButtonView(text: "OpenSSL-Universal", url: "https://github.com/krzyzanowskim/OpenSSL")
				LinkButtonView(text: "RealmSwift", url: "https://realm.io/docs/swift/latest/")
				LinkButtonView(text: "IceCream", url: "https://github.com/caiyue1993/IceCream")
				LinkButtonView(text: "Highlightr", url: "https://github.com/raspu/Highlightr")
				LinkButtonView(text: "SwiftyJSON", url: "https://github.com/SwiftyJSON/SwiftyJSON")
				LinkButtonView(text: "swift-petitparser", url: "https://github.com/philipparndt/swift-petitparser")
			}
		}
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

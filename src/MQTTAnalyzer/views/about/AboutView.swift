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
				
				Text("This project is open source. Contributions are welcome. Feel free to open an issue ticket and discuss new features.")
					.foregroundColor(.secondary)
					.font(.footnote)
				
				LicenseView().padding(.bottom)
				
				Text("Thank you! This project would not be possible without your great work! Thanks for testing, contributing dependencies, features and ideas.")
					.foregroundColor(.secondary)
					.font(.footnote)
				
				List {
					ContributorsView()
					DependenciesView()
				}
				
				Spacer()
			}
			.padding()
			.frame(maxWidth: .infinity, alignment: .leading)
			.multilineTextAlignment(.leading)
			.navigationBarTitle(Text("About"), displayMode: .inline)
			.navigationBarItems(
				leading: Button(action: close) {
					Text("Close")
				}.buttonStyle(ActionStyleT50())
			)
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

					LinkButtonView(text: "© 2020 Philipp Arndt", url: "https://github.com/philipparndt")
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

struct LicenseView: View {
	var body: some View {
		Group {
			HStack {
				LinkButtonView(text: "Source code, ",
							   url: "https://github.com/philipparndt/mqtt-analyzer")
				
				LinkButtonView(text: "License",
						   url: "https://github.com/philipparndt/mqtt-analyzer/blob/master/LICENSE")

			}.font(.footnote)
		}
	}
}

struct DependenciesView: View {
	var body: some View {
		Section(header: Text("Dependencies")) {
			ForEach(dependencies) { dependency in
				LinkButtonView(text: dependency.name, url: dependency.link)
					.font(.footnote)
					.foregroundColor(.blue)
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

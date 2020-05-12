//
//  ContributorsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-12.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ContributorsView: View {
	var body: some View {
		Section(header: Text("Contributors")) {
			ForEach(contributors) { contributor in
				LinkButtonView(text: contributor.name, url: contributor.link)
					.font(.footnote)
					.foregroundColor(.blue)
			}
		}
	}
}

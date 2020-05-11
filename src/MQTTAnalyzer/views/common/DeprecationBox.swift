//
//  DeprecationBox.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DeprecationBox: View {
	var body: some View {
		FillingText(text: "Deprecated setting please migrate to CocoaMQTT client implementation",
		imageName: "exclamationmark.triangle.fill")
		.font(.footnote)
		.padding()
		.foregroundColor(.black)
		.background(Color.yellow)
		.cornerRadius(10)
	}
}

//
//  ResumeConnectionView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2021-06-14.
//  Copyright © 2021 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageLimitReachedView: View {
	
	var body: some View {
		HStack {
			Image(systemName: "exclamationmark.octagon.fill")

			Text("Message limit exceeded.\nReduce the subscription topic!")

			Spacer()
		}
		.padding()
	}
	
}

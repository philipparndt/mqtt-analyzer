//
//  ReconnectView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-07-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct FillingText: View {
	let text: String
	var imageName: String?
	
	var body: some View {
		HStack {
			Text(text)
			
			Spacer()
			
			if imageName != nil {
				Image(systemName: imageName!)
			}
		}
	}
}

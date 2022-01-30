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
		LimitReachedView(message: "Messages per batch limit exceeded.")
	}
	
}

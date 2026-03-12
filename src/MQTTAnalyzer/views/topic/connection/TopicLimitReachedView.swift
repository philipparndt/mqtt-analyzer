//
//  ResumeConnectionView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2021-06-14.
//  Copyright © 2021 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicLimitReachedView: View {

	var onDismiss: (() -> Void)?
	var onOpenSettings: (() -> Void)?

	var body: some View {
		LimitReachedView(
			message: "Topic limit exceeded.",
			onDismiss: onDismiss,
			onOpenSettings: onOpenSettings
		)
	}

}

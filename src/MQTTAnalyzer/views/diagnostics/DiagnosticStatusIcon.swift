//
//  DiagnosticStatusIcon.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-17.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct DiagnosticStatusIcon: View {
	let status: DiagnosticStatus

	var body: some View {
		Group {
			switch status {
			case .pending:
				Image(systemName: "circle.dashed")
					.foregroundColor(.secondary)

			case .running:
				ProgressView()
					.controlSize(.small)

			case .success:
				Image(systemName: "checkmark.circle.fill")
					.foregroundColor(.green)

			case .warning:
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundColor(.orange)

			case .error:
				Image(systemName: "xmark.circle.fill")
					.foregroundColor(.red)
			}
		}
		.font(.system(size: 18, weight: .medium))
		.frame(width: 24, height: 24)
	}
}

struct DiagnosticStatusIcon_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 20) {
			DiagnosticStatusIcon(status: .pending)
			DiagnosticStatusIcon(status: .running)
			DiagnosticStatusIcon(status: .success)
			DiagnosticStatusIcon(status: .warning("Test warning"))
			DiagnosticStatusIcon(status: .error("Test error"))
		}
		.padding()
	}
}

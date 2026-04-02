//
//  SignalHandler.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation

private var cleanupAction: (() -> Void)?

func setupSignalHandler(cleanup: @escaping () -> Void) {
    cleanupAction = cleanup

    signal(SIGINT) { _ in
        cleanupAction?()
    }
    signal(SIGTERM) { _ in
        cleanupAction?()
    }
}

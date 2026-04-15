//
//  main.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

// Suppress CocoaMQTT internal logging (the CLI has its own error reporting)
CocoaMQTTLogger.logger.minLevel = .off

// Register value transformers before CoreData loads the model
ValueTransformer.setValueTransformer(
    SubscriptionValueTransformer(),
    forName: NSValueTransformerName("SubscriptionValueTransformer")
)
ValueTransformer.setValueTransformer(
    CertificateValueTransformer(),
    forName: NSValueTransformerName("CertificateValueTransformer")
)

MQTTAnalyzerCommand.main()

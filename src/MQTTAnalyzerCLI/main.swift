//
//  main.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation

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

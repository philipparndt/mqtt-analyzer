//
//  ListCommand.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

import Foundation
import ArgumentParser

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all configured brokers"
    )

    func run() throws {
        let brokers = try BrokerLoader.loadAllBrokers()

        if brokers.isEmpty {
            throw BrokerLoaderError.noBrokersConfigured
        }

        for broker in brokers.sorted(by: { $0.alias < $1.alias }) {
            print(broker.alias)
        }
    }
}

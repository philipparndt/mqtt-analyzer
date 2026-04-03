//
//  MQTTAnalyzerCommand.swift
//  MQTTAnalyzerCLI
//
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import Foundation
import ArgumentParser

func resolveAppVersion() -> String {
    // Try Bundle.main first (works if CLI is the main executable of a bundle)
    if let version = bundleVersion(Bundle.main) {
        return version
    }

    // Walk up from executable to find enclosing .app bundle
    var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
    var size = UInt32(MAXPATHLEN)
    if _NSGetExecutablePath(&buffer, &size) == 0 {
        let execURL = URL(fileURLWithPath: String(cString: buffer)).resolvingSymlinksInPath()
        var current = execURL.deletingLastPathComponent()
        while current.path != "/" {
            if current.pathExtension == "app", let appBundle = Bundle(url: current),
               let version = bundleVersion(appBundle) {
                return version
            }
            current = current.deletingLastPathComponent()
        }
    }

    return "unknown"
}

private func bundleVersion(_ bundle: Bundle) -> String? {
    guard let marketing = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
          let build = bundle.infoDictionary?["CFBundleVersion"] as? String else {
        return nil
    }
    return "\(marketing).\(build)"
}

let cliVersion = resolveAppVersion()

struct MQTTAnalyzerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mqtt-analyzer",
        abstract: "MQTT Analyzer command-line tool",
        version: cliVersion,
        subcommands: [ListCommand.self, SubscribeCommand.self, PublishCommand.self, VersionCommand.self]
    )
}

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Print the version"
    )

    func run() {
        print(cliVersion)
    }
}

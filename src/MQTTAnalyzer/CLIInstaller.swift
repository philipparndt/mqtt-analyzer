//
//  CLIInstaller.swift
//  MQTTAnalyzer
//
//  Copyright © 2024 Philipp Arndt. All rights reserved.
//

#if os(macOS)
import Foundation
import AppKit

struct CLIManualCommand: Identifiable {
    let id = UUID()
    let command: String
}

enum CLIInstallResult {
    case success
    case needsManualInstall(command: String)
    case error(String)
}

enum CLIUninstallResult {
    case success
    case needsManualUninstall(command: String)
    case error(String)
}

class CLIInstaller {
    static let installPath = "/usr/local/bin/mqtt-analyzer"

    static var cliSourcePath: String? {
        Bundle.main.executableURL?
            .deletingLastPathComponent()
            .appendingPathComponent("mqtt-analyzer")
            .path
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: installPath)
    }

    static func install(completion: @escaping (CLIInstallResult) -> Void) {
        guard let sourcePath = cliSourcePath else {
            completion(.error("CLI binary not found in application bundle"))
            return
        }

        guard FileManager.default.fileExists(atPath: sourcePath) else {
            completion(.error("CLI binary not found in application bundle"))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            do {
                if fileManager.fileExists(atPath: installPath) {
                    try fileManager.removeItem(atPath: installPath)
                }
                try fileManager.createSymbolicLink(atPath: installPath, withDestinationPath: sourcePath)
                DispatchQueue.main.async {
                    completion(.success)
                }
            } catch {
                let command = "sudo ln -sf '\(sourcePath)' '\(installPath)'"
                DispatchQueue.main.async {
                    completion(.needsManualInstall(command: command))
                }
            }
        }
    }

    static func uninstall(completion: @escaping (CLIUninstallResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: installPath)
                DispatchQueue.main.async {
                    completion(.success)
                }
            } catch {
                let command = "sudo rm -f '\(installPath)'"
                DispatchQueue.main.async {
                    completion(.needsManualUninstall(command: command))
                }
            }
        }
    }

    static func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
#endif

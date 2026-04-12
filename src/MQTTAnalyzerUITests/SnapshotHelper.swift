// SnapshotHelper.swift
//
// delivr — Drop-in replacement for fastlane's SnapshotHelper.
// Add this file to your UI test target. Call snapshot("Name") to capture.
//
// Before running tests, delivr writes a config JSON to
// ~/Library/Caches/tools.delivr/snapshot-config.json
// with the device name and output path.

import Foundation
import XCTest

// MARK: - Public API

/// Initialize the snapshot system. Call this in your test setUp().
@MainActor
func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

/// Capture a screenshot and save it as {DeviceName}-{name}.png
@MainActor
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    Snapshot.snapshot(name, timeWaitingForIdle: timeout)
}

/// Overload for compatibility with fastlane's waitForLoadingIndicator parameter
@MainActor
func snapshot(_ name: String, waitForLoadingIndicator: Bool) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

// MARK: - Implementation

@objcMembers
@MainActor
open class Snapshot: NSObject {
    static var app: XCUIApplication?
    static var deviceName: String = ""
    static var outputDir: String = ""
    static var waitForAnimations: Bool = true
    static var cacheDirectory: URL?

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        self.app = app
        self.waitForAnimations = waitForAnimations

        // Load delivr config
        if let config = loadConfig() {
            deviceName = config.deviceName
            outputDir = config.outputDir
            NSLog("delivr: Configured for device '\(deviceName)', output: \(outputDir)")
        } else {
            // Fallback: use simulator device name from environment
            deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Unknown"
            outputDir = NSTemporaryDirectory()
            NSLog("delivr: No config found, using fallback: \(deviceName)")
        }

        app.launchArguments += ["-DELIVR_SNAPSHOT", "YES", "-ui_testing"]
    }

    class func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        guard let app = app else {
            NSLog("delivr: SnapshotHelper not initialized. Call setupSnapshot() first.")
            return
        }

        if waitForAnimations {
            sleep(1) // Brief pause for animations to settle
        }

        // Capture screenshot
        let screenshot = app.windows.firstMatch.screenshot()
        let imageData = screenshot.pngRepresentation

        // Build output path
        let fileName = "\(deviceName)-\(name).png"
        let outputPath = (outputDir as NSString).appendingPathComponent(fileName)

        // Ensure output directory exists
        try? FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Write screenshot
        do {
            try imageData.write(to: URL(fileURLWithPath: outputPath))
            NSLog("delivr: Saved screenshot: \(outputPath)")
        } catch {
            NSLog("delivr: Failed to save screenshot: \(error)")
        }
    }

    // MARK: - Config

    // swiftlint:disable:next nesting
    struct DelivrConfig: Codable {
        let deviceName: String
        let outputDir: String

        enum CodingKeys: String, CodingKey {
            case deviceName = "device_name"
            case outputDir = "output_dir"
        }
    }

    class func loadConfig() -> DelivrConfig? {
        let cachePath = "Library/Caches/tools.delivr"

        // Determine UDID for per-device config lookup
        let udid: String
        #if os(macOS)
            udid = "macos"
            let homeDir = URL(fileURLWithPath: NSHomeDirectory())
        #else
            guard let simUDID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] else {
                NSLog("delivr: SIMULATOR_UDID not set — running on physical device?")
                return nil
            }
            udid = simUDID
            guard let simulatorHostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else {
                NSLog("delivr: SIMULATOR_HOST_HOME not set")
                return nil
            }
            let homeDir = URL(fileURLWithPath: simulatorHostHome)
        #endif

        let configURL = homeDir
            .appendingPathComponent(cachePath)
            .appendingPathComponent("snapshot-config-\(udid).json")

        guard let data = try? Data(contentsOf: configURL) else {
            NSLog("delivr: Config not found at \(configURL.path)")
            return nil
        }

        return try? JSONDecoder().decode(DelivrConfig.self, from: data)
    }
}

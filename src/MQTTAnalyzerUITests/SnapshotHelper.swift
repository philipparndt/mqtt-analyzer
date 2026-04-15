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
#if os(macOS)
import AppKit
#endif

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
    static var windowSize: (width: Int, height: Int)?
    static var windowResized: Bool = false

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        self.app = app
        self.waitForAnimations = waitForAnimations

        // Load delivr config
        if let config = loadConfig() {
            deviceName = config.deviceName

            #if os(macOS)
            // macOS test runners are sandboxed — write screenshots into the
            // sandbox container's caches dir, which is always writable.
            let containerCaches = NSHomeDirectory() + "/Library/Caches/tools.delivr/screenshots"
            outputDir = containerCaches

            NSLog("delivr: macOS sandbox — writing to \(outputDir)")

            if let ws = config.windowSize, ws.count == 2, ws[0] > 0 && ws[1] > 0 {
                windowSize = (width: ws[0], height: ws[1])
                NSLog("delivr: Will resize window to \(ws[0])x\(ws[1])")
            }
            #else
            outputDir = config.outputDir
            #endif

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

        #if os(macOS)
        // Resize window on first snapshot call (after app has launched)
        if !windowResized, let size = windowSize {
            windowResized = true
            let appName = app.label.isEmpty ? "MQTTAnalyzer" : app.label
            let script = """
            tell application "System Events"
                tell process "\(appName)"
                    set frontmost to true
                    delay 0.3
                    tell window 1
                        set size to {\(size.width), \(size.height)}
                        set position to {100, 100}
                    end tell
                end tell
            end tell
            """
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            if let error = error {
                NSLog("delivr: Window resize failed: \(error)")
            } else {
                NSLog("delivr: Resized window to \(size.width)x\(size.height)")
            }
            sleep(1) // Wait for layout to settle
        }
        #endif

        if waitForAnimations {
            sleep(1) // Brief pause for animations to settle
        }

        // Build output path
        let fileName = "\(deviceName)-\(name).png"
        let outputPath = (outputDir as NSString).appendingPathComponent(fileName)

        // Ensure output directory exists
        try? FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        #if os(macOS)
        // Use screencapture -l to capture the window with proper rounded
        // corners and drop shadow, like pressing Space in screenshot mode.
        if let windowID = findWindowID(for: app) {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            task.arguments = ["-l", String(windowID), outputPath]
            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    NSLog("delivr: Saved screenshot (screencapture): \(outputPath)")
                    return
                }
                NSLog("delivr: screencapture failed with status \(task.terminationStatus), falling back to XCTest")
            } catch {
                NSLog("delivr: screencapture error: \(error), falling back to XCTest")
            }
        }
        #endif

        // Fallback: XCTest screenshot (iOS, or macOS if screencapture fails)
        let screenshot = app.windows.firstMatch.screenshot()
        let imageData = screenshot.pngRepresentation
        do {
            try imageData.write(to: URL(fileURLWithPath: outputPath))
            NSLog("delivr: Saved screenshot: \(outputPath)")
        } catch {
            NSLog("delivr: Failed to save screenshot: \(error)")
        }
    }

    // MARK: - macOS Window ID

    #if os(macOS)
    /// Find the CGWindowID for the app's main window.
    /// Matches the frontmost app that isn't the test runner or system processes.
    class func findWindowID(for app: XCUIApplication) -> CGWindowID? {
        // swiftlint:disable:next line_length
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        // The frontmost app (set by our AppleScript resize) is the target.
        // Find it via NSWorkspace — it's the app we're testing.
        let myPID = ProcessInfo.processInfo.processIdentifier
        let ignoredNames: Set<String> = ["Finder", "Dock", "SystemUIServer", "Control Center",
                                          "WindowManager", "Notification Center"]

        // Try the frontmost app first
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != myPID {
            let pid = frontmost.processIdentifier
            for window in windowList {
                guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                      let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                      let layer = window[kCGWindowLayer as String] as? Int,
                      layer == 0, ownerPID == pid
                else { continue }
                NSLog("delivr: Found window ID \(windowID) for frontmost app '\(frontmost.localizedName ?? "?")'")
                return windowID
            }
        }

        // Fallback: find the first normal-layer window that isn't a system process
        for window in windowList {
            guard let ownerName = window[kCGWindowOwnerName as String] as? String,
                  let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  ownerPID != myPID,
                  !ignoredNames.contains(ownerName)
            else { continue }
            NSLog("delivr: Found window ID \(windowID) for '\(ownerName)' (fallback)")
            return windowID
        }

        NSLog("delivr: No suitable window found")
        return nil
    }
    #endif

    // MARK: - Config

    // swiftlint:disable:next nesting
    struct DelivrConfig: Codable {
        let deviceName: String
        let outputDir: String
        let windowSize: [Int]?

        enum CodingKeys: String, CodingKey {
            case deviceName = "device_name"
            case outputDir = "output_dir"
            case windowSize = "window_size"
        }
    }

    class func loadConfig() -> DelivrConfig? {
        let cachePath = "Library/Caches/tools.delivr"

        // Determine UDID for per-device config lookup
        let udid: String
        #if os(macOS)
            udid = "macos"
            // NSHomeDirectory() returns the sandbox container path on macOS,
            // so we resolve the real home via the passwd database.
            let pw = getpwuid(getuid())
            let realHome = pw.map { String(cString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
            let homeDir = URL(fileURLWithPath: realHome)
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

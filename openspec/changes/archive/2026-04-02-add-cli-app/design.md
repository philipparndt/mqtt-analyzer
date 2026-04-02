## Context

MQTT Analyzer is a SwiftUI macOS/iOS app for inspecting MQTT traffic. The core MQTT logic lives in a shared `Common` framework (CocoaMQTT-based clients, BrokerSetting CoreData model, TopicTree, MsgMessage). Broker configurations are persisted in CoreData. The macOS app is distributed via the App Store and Homebrew. There is currently no CLI target in the Xcode project.

## Goals / Non-Goals

**Goals:**
- Provide a CLI tool (`mqtt-analyzer`) that can subscribe to topics and publish messages from the terminal
- Allow broker selection by name (`-s "system name"`) using brokers already configured in the GUI app
- Bundle the CLI binary inside the macOS app bundle so it ships automatically
- Provide a menu item in the macOS app to symlink/install the CLI onto the user's PATH
- Reuse existing Common framework code for MQTT connectivity

**Non-Goals:**
- The CLI does not need to create or edit broker configurations (use the GUI for that)
- No interactive TUI or curses-based interface — stdout streaming is sufficient
- No iOS support for the CLI
- No separate distribution of the CLI outside the macOS app bundle (Homebrew ships the app which contains the CLI)

## Decisions

### 1. CLI as a separate executable target in the Xcode workspace

**Decision:** Add a new Swift command-line tool target (`MQTTAnalyzerCLI`) to the existing Xcode project that links against the Common framework.

**Rationale:** This allows full code reuse of BrokerSetting, CocoaMQTT clients, and TopicTree. A separate SPM package was considered but would duplicate dependency management and complicate the build.

**Alternative considered:** A standalone SPM executable — rejected because it would need to duplicate or extract Common into its own package, which is a larger refactor.

### 2. Swift Argument Parser for CLI interface

**Decision:** Use Apple's `swift-argument-parser` package for command parsing.

**Rationale:** It's the standard Swift CLI framework, provides auto-generated help, supports subcommands, and integrates cleanly with SPM/Xcode. CocoaMQTT already requires a RunLoop, and ArgumentParser works well with that.

### 3. Shared broker configuration via CoreData store path

**Decision:** The CLI reads the same CoreData SQLite store used by the macOS app. The store path is resolved using the app's container directory (`~/Library/Containers/de.rnd7.MQTTAnalyzer/Data/` for sandboxed, or the Application Support path for non-sandboxed builds).

**Rationale:** This avoids any sync mechanism — the CLI reads broker configs directly. Since the CLI is a helper tool (not running simultaneously with active editing), read-only access to the store is sufficient.

**Alternative considered:** Using exported `.mqttbroker` JSON files — rejected because it requires manual export steps and doesn't stay in sync automatically.

### 4. CLI binary embedded in the app bundle

**Decision:** The CLI binary is placed in `Contents/MacOS/` of the macOS app bundle as a secondary executable (e.g., `MQTTAnalyzer.app/Contents/MacOS/mqtt-analyzer`).

**Rationale:** Binaries in `Contents/MacOS/` are code-signed alongside the app, which is required for notarization. Resources directory would require separate signing.

### 5. Menu item to install CLI via symlink

**Decision:** A menu item "Install Command Line Tool..." in the macOS app creates a symlink from `/usr/local/bin/mqtt-analyzer` to the binary inside the app bundle. The app uses an authorization prompt (or `NSAppleScript` with admin privileges) if `/usr/local/bin/` requires elevated permissions.

**Rationale:** This is the same pattern used by Xcode ("Install Command Line Tools"), Docker Desktop, and other macOS apps. Users get a familiar experience.

### 6. CLI subcommand structure

**Decision:**
```
mqtt-analyzer -s "broker name" subscribe [topic] [--qos 0|1|2] [--json]
mqtt-analyzer -s "broker name" publish [topic] [message] [--qos 0|1|2] [--retain]
mqtt-analyzer list
```

- `subscribe`: Connects and streams messages to stdout (one per line). `--json` outputs structured JSON per message.
- `publish`: Publishes a single message and exits.
- `list`: Lists all configured brokers/systems.

**Rationale:** Subcommand pattern is standard for CLI tools. The `-s` flag is a global option. `list` helps users discover available broker names.

## Risks / Trade-offs

- **[CoreData access from CLI]** → The CLI links CoreData and reads the GUI's store. If the store schema changes, both targets must be updated together. Mitigated by sharing the same Common framework and model definitions.
- **[Sandboxing constraints]** → If the macOS app is sandboxed, the CLI (running outside the sandbox) may not be able to read the app's container. Mitigated by using a shared App Group container or falling back to a known path. The Homebrew build is not sandboxed, which simplifies this.
- **[Symlink installation permissions]** → Creating symlinks in `/usr/local/bin/` may require admin privileges. Mitigated by using `AuthorizationExecuteWithPrivileges` or prompting the user to run the install command manually.
- **[CocoaMQTT RunLoop requirement]** → CocoaMQTT requires a RunLoop for its networking. The CLI must run `RunLoop.main` or use `dispatchMain()` to keep the process alive during subscribe. This is standard for network-based CLI tools in Swift.

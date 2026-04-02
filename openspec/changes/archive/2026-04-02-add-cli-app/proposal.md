## Why

MQTT Analyzer is a powerful GUI tool for inspecting MQTT traffic, but power users and automation workflows need command-line access to quickly subscribe to topics or publish messages without opening the full app. A bundled CLI tool enables scripting, CI/CD integration, and faster ad-hoc debugging directly from the terminal.

## What Changes

- Add a new Swift CLI executable (`mqtt-analyzer`) bundled inside the macOS app bundle
- CLI supports selecting a configured broker/system with `-s "system name"` (using brokers already configured in the GUI app)
- CLI can subscribe to topics and stream incoming messages to stdout
- CLI can publish messages to topics
- Add a menu item in the macOS app UI to register/install the CLI tool to a location on the user's `$PATH` (e.g., symlink to `/usr/local/bin/mqtt-analyzer`)
- CLI reads broker configurations from the shared app data (CoreData store or exported broker files)

## Capabilities

### New Capabilities
- `cli-core`: Core CLI executable with argument parsing, broker selection (`-s`), subscribe, and publish commands
- `cli-install`: Menu item in the macOS app to register/install the CLI tool on the user's PATH

### Modified Capabilities
_None — this is additive and does not change existing app behavior._

## Impact

- **Xcode project**: New CLI executable target added to the workspace
- **macOS app bundle**: CLI binary embedded in the app bundle (e.g., `Contents/MacOS/mqtt-analyzer-cli` or `Contents/Resources/`)
- **Shared data access**: CLI needs read access to the same CoreData store or broker configuration used by the macOS app (via App Group or direct file path)
- **Dependencies**: Reuses CocoaMQTT from Common; adds Swift Argument Parser for CLI argument handling
- **Build/release**: Homebrew and macOS app distribution must include the CLI binary
- **Code reuse**: Leverages existing `Common` framework (BrokerSetting, MQTTClientCocoaMQTT, MQTTSessionController)

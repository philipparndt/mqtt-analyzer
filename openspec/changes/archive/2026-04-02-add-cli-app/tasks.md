## 1. Project Setup

- [x] 1.1 Add Swift Argument Parser package dependency to the Xcode project
- [x] 1.2 Create new CLI executable target (`MQTTAnalyzerCLI`) in the Xcode project that links Common framework and ArgumentParser
- [x] 1.3 Configure the CLI target to output the binary as `mqtt-analyzer`
- [x] 1.4 Ensure the CLI target can access CoreData model and BrokerSetting entities from Common

## 2. Broker Configuration Access

- [x] 2.1 Implement a function to resolve the CoreData store path used by the macOS app (handle sandboxed and non-sandboxed paths)
- [x] 2.2 Implement a read-only broker loading service that fetches all BrokerSetting entries from the store
- [x] 2.3 Implement broker lookup by alias name for the `-s` / `--system` option

## 3. CLI Command Structure

- [x] 3.1 Implement the root command with `-s` / `--system` global option using ArgumentParser
- [x] 3.2 Implement the `list` subcommand that prints all broker aliases
- [x] 3.3 Implement the `subscribe` subcommand with topic argument, `--qos`, and `--json` options
- [x] 3.4 Implement the `publish` subcommand with topic and message arguments, `--qos`, `--retain` options, and stdin support (`-`)

## 4. MQTT Connection from CLI

- [x] 4.1 Create a CLI-specific MQTT connection handler that reuses Common's CocoaMQTT clients (MQTT 3.1.1 and 5.0)
- [x] 4.2 Set up RunLoop / dispatchMain for keeping the CLI process alive during subscribe
- [x] 4.3 Implement message output formatting: tab-separated (`topic\tpayload`) and JSON mode
- [x] 4.4 Implement connection error handling with meaningful error messages and exit codes
- [x] 4.5 Implement clean disconnect and graceful shutdown on SIGINT/SIGTERM

## 5. App Bundle Integration

- [x] 5.1 Add a "Copy Files" build phase to the macOS app target to embed the CLI binary in `Contents/MacOS/`
- [x] 5.2 Verify the CLI binary is included in code signing and notarization

## 6. Menu Item for CLI Installation

- [x] 6.1 Add "Install Command Line Tool..." menu item to the macOS app menu bar
- [x] 6.2 Implement symlink creation from `/usr/local/bin/mqtt-analyzer` to the app bundle binary, with admin privilege escalation when needed
- [x] 6.3 Add "Uninstall Command Line Tool..." menu item that removes the symlink
- [x] 6.4 Implement menu state: reflect whether the CLI is currently installed (enable/disable uninstall, show reinstall label)

## 7. Testing

- [x] 7.1 Add unit tests for broker configuration loading and alias lookup
- [x] 7.2 Add unit tests for CLI argument parsing (all subcommands and options)
- [ ] 7.3 Add integration test: subscribe to a topic and verify message output format
- [ ] 7.4 Add integration test: publish a message and verify delivery

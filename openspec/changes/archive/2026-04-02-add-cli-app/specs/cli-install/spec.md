## ADDED Requirements

### Requirement: CLI binary is bundled in the macOS app
The macOS app bundle SHALL contain the CLI executable at `Contents/MacOS/mqtt-analyzer` so it is code-signed and notarized alongside the app.

#### Scenario: CLI binary exists in app bundle
- **WHEN** the macOS app is built
- **THEN** the CLI executable is present at `MQTTAnalyzer.app/Contents/MacOS/mqtt-analyzer`

#### Scenario: CLI binary is code-signed
- **WHEN** the macOS app is signed for distribution
- **THEN** the CLI binary is included in the code signature

### Requirement: Menu item to install CLI tool
The macOS app SHALL provide a menu item "Install Command Line Tool..." that creates a symlink from `/usr/local/bin/mqtt-analyzer` to the CLI binary inside the app bundle.

#### Scenario: Install CLI via menu
- **WHEN** user selects "Install Command Line Tool..." from the app menu
- **THEN** the app creates a symlink at `/usr/local/bin/mqtt-analyzer` pointing to the CLI binary in the app bundle
- **AND** the app shows a success confirmation

#### Scenario: Install requires elevated permissions
- **WHEN** the user selects "Install Command Line Tool..." and `/usr/local/bin/` is not writable
- **THEN** the app requests administrator privileges before creating the symlink

#### Scenario: CLI already installed
- **WHEN** the user selects "Install Command Line Tool..." and `/usr/local/bin/mqtt-analyzer` already exists
- **THEN** the app replaces the existing symlink and shows a success confirmation

### Requirement: Menu item to uninstall CLI tool
The macOS app SHALL provide a menu item "Uninstall Command Line Tool..." that removes the symlink.

#### Scenario: Uninstall CLI via menu
- **WHEN** user selects "Uninstall Command Line Tool..." from the app menu
- **THEN** the app removes the symlink at `/usr/local/bin/mqtt-analyzer`
- **AND** the app shows a confirmation that the CLI tool was removed

#### Scenario: CLI not installed
- **WHEN** user selects "Uninstall Command Line Tool..." and no symlink exists
- **THEN** the app shows a message indicating the CLI tool is not installed

### Requirement: Menu reflects installation state
The macOS app menu SHALL indicate whether the CLI tool is currently installed.

#### Scenario: CLI is installed
- **WHEN** the symlink at `/usr/local/bin/mqtt-analyzer` exists and points to the app bundle
- **THEN** the "Install Command Line Tool..." menu item shows as "Reinstall Command Line Tool..." or is visually distinguished

#### Scenario: CLI is not installed
- **WHEN** no symlink exists at `/usr/local/bin/mqtt-analyzer`
- **THEN** the "Uninstall Command Line Tool..." menu item is disabled or hidden

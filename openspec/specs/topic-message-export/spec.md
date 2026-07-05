## ADDED Requirements

### Requirement: Subtree snapshot collection

The system SHALL collect, for a selected topic, the most recent message of that topic and the most recent message of every descendant (child, grandchild, etc.) topic that has at least one message. Topics without any message SHALL be omitted from the snapshot. Each collected entry SHALL include the fully qualified topic name, the payload, and the message metadata (retain flag, QoS, timestamp).

#### Scenario: Collect recent messages across the subtree

- **WHEN** the user triggers the subtree export action on topic `home`
- **THEN** the snapshot includes the recent message of `home` (if any) and the recent message of each descendant such as `home/livingroom/temp` and `home/kitchen/light`

#### Scenario: Topics without messages are skipped

- **WHEN** a descendant topic exists in the tree but has never received a message
- **THEN** that topic is not present in the generated snapshot

#### Scenario: Leaf topic export

- **WHEN** the user triggers the action on a leaf topic that has no children
- **THEN** the snapshot contains only that topic's most recent message

### Requirement: Verbatim and binary payloads

The system SHALL preserve each payload exactly as received. Text (UTF-8) payloads SHALL be kept verbatim as their original string and SHALL NOT be re-serialized into the export format (a JSON message stays JSON). Binary (non-UTF-8) payloads SHALL be exported without loss as Base64-encoded data, marked with an encoding indicator; the system SHALL NOT export a size placeholder in place of binary content.

#### Scenario: JSON payload stays JSON

- **WHEN** a topic's payload is a JSON document and the subtree is exported as YAML
- **THEN** the payload is emitted verbatim as the original JSON text (not converted into YAML structure)

#### Scenario: Binary payload is exported as Base64

- **WHEN** a topic's most recent message contains binary (non-UTF-8) data
- **THEN** the export contains the full payload Base64-encoded and marked as `base64` encoding, with no size placeholder such as `[N bytes]`

#### Scenario: Text payload has no encoding marker

- **WHEN** a topic's payload is valid UTF-8 text
- **THEN** the entry contains the raw text and omits the encoding marker

### Requirement: JSON serialization

The system SHALL serialize the subtree snapshot to human-readable, pretty-printed JSON with deterministic ordering (topics sorted by qualified name) so output is stable and diff-friendly.

#### Scenario: Export subtree as JSON

- **WHEN** the user selects the JSON format for a subtree export
- **THEN** the system produces valid, pretty-printed JSON representing each topic's qualified name, payload, and metadata

#### Scenario: Stable ordering

- **WHEN** the same subtree snapshot is exported as JSON twice without changes
- **THEN** both outputs are byte-identical

### Requirement: YAML serialization

The system SHALL serialize the subtree snapshot to human-readable YAML representing the same data as the JSON output.

#### Scenario: Export subtree as YAML

- **WHEN** the user selects the YAML format for a subtree export
- **THEN** the system produces valid YAML representing each topic's qualified name, payload, and metadata

### Requirement: Copy to clipboard

The system SHALL allow the serialized subtree snapshot (JSON or YAML) to be copied to the system clipboard on both iOS and macOS.

#### Scenario: Copy JSON to clipboard

- **WHEN** the user chooses "Copy subtree as JSON"
- **THEN** the JSON serialization of the snapshot is placed on the clipboard and can be pasted into another application

#### Scenario: Copy YAML to clipboard

- **WHEN** the user chooses "Copy subtree as YAML"
- **THEN** the YAML serialization of the snapshot is placed on the clipboard

### Requirement: Export to file

The system SHALL allow the serialized subtree snapshot to be saved/shared as a file with an appropriate extension (`.json` or `.yaml`) and a default filename derived from the topic name.

#### Scenario: Export JSON to file

- **WHEN** the user chooses to export the subtree as a JSON file
- **THEN** the system presents the platform file export/share UI with a `.json` file containing the snapshot and a default name based on the selected topic

#### Scenario: Export YAML to file

- **WHEN** the user chooses to export the subtree as a YAML file
- **THEN** the system presents the platform file export/share UI with a `.yaml` file containing the snapshot

### Requirement: Action availability in topic UI

The system SHALL expose the subtree copy/export actions from the topic context menu in the topic tree, alongside the existing copy actions.

#### Scenario: Action present in topic context menu

- **WHEN** the user opens the context menu on a topic in the topic tree
- **THEN** subtree copy/export options (JSON and YAML) are available

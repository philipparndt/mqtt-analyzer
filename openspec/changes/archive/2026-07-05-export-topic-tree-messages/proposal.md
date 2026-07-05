## Why

When inspecting an MQTT broker, a topic usually represents a whole subtree (e.g. `home/livingroom/...`) rather than a single leaf. Today users can only copy a single topic's recent message; there is no way to grab the current state of a topic together with all of its children. Capturing a full subtree snapshot is needed for sharing, debugging, diffing device state, and pasting into issues or documentation.

## What Changes

- Add a "copy/export subtree" action to a topic in the topic tree that captures the most recent message of the selected topic **and all descendant topics**.
- Support two serialization formats: **JSON** and **YAML**.
- Allow the result to be **copied to the clipboard** (cross-platform via the existing `Pasteboard` abstraction) and **exported to a file** (via the existing `fileExporter` pattern), on both iOS and macOS.
- Introduce a YAML serialization capability (new dependency, since no YAML support exists today).
- The export structure preserves the topic hierarchy and includes per-message metadata (qualified topic, payload, retain, QoS, timestamp).

## Capabilities

### New Capabilities
- `topic-message-export`: Collecting the recent message of a topic and all descendant topics and serializing the subtree snapshot to JSON or YAML, exposed via clipboard copy and file export in the app UI.

### Modified Capabilities
<!-- No existing spec-level requirements change; cli-core / cli-install are unrelated. -->

## Impact

- **Code**: New serialization/model code under `src/Common/model` (subtree export model + JSON/YAML encoders). New UI actions in the topic context menus — `src/MQTTAnalyzer/views/topic/TopicTreeView.swift` (TreeNodeCellView) and `src/MQTTAnalyzer/views/topic/TopicCellView.swift`.
- **Reuse**: `TopicTree.recusiveAllMessages` for descendant traversal, `Pasteboard.copy` for clipboard, `TextFileDocument` + `.fileExporter` for file export.
- **Dependencies**: None added — YAML output uses a small self-contained emitter in `Common` (avoids `project.pbxproj` package surgery).
- **Platforms**: iOS and macOS (shared `Common` code; platform-specific share/export entry points).

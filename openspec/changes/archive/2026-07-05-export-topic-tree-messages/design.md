## Context

MQTT Analyzer models the broker as a `TopicTree` (`src/Common/model/tree/TopicTree.swift`), where each node holds `messages: [MsgMessage]`, a `children: [String: TopicTree]` map, a `parent`, and a computed `nameQualified`. Descendant traversal already exists via `TopicTree+Flatten.swift` (`recusiveAllMessages`) and `TopicTree+Counter.swift`.

Existing copy support is single-value only: `Pasteboard.copy(_:)` (`src/Common/platform/PlatformCompat.swift`) backs "Copy topic" / "Copy recent message" context-menu actions in `TopicTreeView.swift` (TreeNodeCellView) and `TopicCellView.swift`. File export already has a reusable pattern: `TextFileDocument: FileDocument` + `.fileExporter` in `MessageDetailsJsonView.swift`, and `BrokerExportModel.swift` shows the `JSONEncoder` (`.prettyPrinted`, `.sortedKeys`) convention. There is currently **no YAML support** anywhere in the project.

This change adds a subtree-level snapshot: collect the latest message of a topic and all descendants, then serialize to JSON or YAML for clipboard or file.

## Goals / Non-Goals

**Goals:**
- Capture the most-recent message per topic across an entire subtree into a stable, serializable model.
- Serialize that model to pretty-printed JSON and to YAML.
- Surface copy-to-clipboard and export-to-file actions in the topic context menu on iOS and macOS.
- Maximize reuse of existing traversal, pasteboard, and file-export code.

**Non-Goals:**
- Exporting full message history (only the latest message per topic).
- Importing/round-tripping the exported snapshot back into the app.
- Streaming/continuous export or scheduled exports.
- Changing the CLI (`cli-core`) — this is an app UI feature.

## Decisions

### Snapshot data model (Codable)
Introduce a dedicated `Codable` export model in `src/Common/model`, e.g. `TopicTreeExport`:

```
struct TopicMessageExport: Codable {
    let topic: String        // nameQualified
    let payload: <string|json> // payload.dataString, with structured JSON when isJSON
    let retain: Bool
    let qos: Int32
    let timestamp: String    // ISO-8601
}
struct TopicTreeExport: Codable {
    let root: String                  // selected topic nameQualified
    let exportedAt: String            // ISO-8601
    let messages: [TopicMessageExport]
}
```

- Build the list from `node.recusiveAllMessages` (already sorted), taking `messages.last` per node, skipping nodes with no message.
- Sort `messages` by `topic` for deterministic output. **Why:** stable, diff-friendly output (matches `.sortedKeys` intent of the broker export).
- Payload representation: the payload is preserved **verbatim** and is never re-serialized into the export format. Text (UTF-8) payloads are kept as their raw string (`payload.dataString`); a JSON message therefore stays JSON even inside a YAML export. In YAML, any string that would otherwise need escaping (e.g. JSON) is emitted as a block-literal (`|-`) scalar so the exact bytes are preserved without escape noise. Binary (non-UTF-8) payloads are exported without loss as Base64 (`Data(payload.data).base64EncodedString()`) with a `payloadEncoding: "base64"` marker (omitted for text). *Alternatives considered:* (a) parse JSON payloads into structured nodes — rejected: it mutates the payload during export; (b) keep the `[N bytes]` placeholder for binary — rejected: it loses the actual data the user wants to export.

### JSON serialization
Use `JSONEncoder` with `.prettyPrinted` + `.sortedKeys`, mirroring `BrokerExportModel.encode()`. **Why:** zero new dependency, already the project convention.

### YAML serialization — self-contained emitter
Implement a small, self-contained YAML emitter in `Common` rather than adding a dependency. **Why:** adding the Yams SPM package requires hand-editing `project.pbxproj` to wire the package into both the iOS and macOS app targets (remote package ref, per-target product dependency, build-file/link entries), which is fragile and hard to verify without a full `xcodebuild`. Because we fully control the export model, the value space is small and well-defined (string, int, bool, null, nested dictionaries from parsed JSON, arrays), so a minimal emitter is tractable and keeps the build unchanged. *Alternatives considered:* (a) add **Yams** and `YAMLEncoder` — rejected here due to pbxproj surgery / build-verification risk; (b) skip YAML — rejected, explicitly requested. The emitter handles proper scalar quoting/escaping (double-quote when the value contains YAML-special characters or could be misparsed) and block-style nesting with 2-space indent.

### UI entry points
Add a submenu/group of actions to the existing topic context menus in `TopicTreeView.swift` (TreeNodeCellView, ~line 538) and `TopicCellView.swift` (~line 39): "Copy subtree as JSON", "Copy subtree as YAML", "Export subtree…". Copy uses `Pasteboard.copy`. File export reuses the `TextFileDocument` + `.fileExporter` pattern from `MessageDetailsJsonView.swift`, with default filename derived from the topic name (sanitized, e.g. `home_livingroom.json`). **Why:** consistent with existing copy actions and the proven export pattern; shared serialization lives in `Common` so both menus call the same code.

### Serialization placement
Put serialization in `Common` (shared between iOS/macOS targets) as a small service/extension producing `String`/`Data`. UI layers only handle presentation (clipboard vs. fileExporter/share sheet).

## Risks / Trade-offs

- **Large subtrees produce large output** → Only the latest message per topic is included (not history), bounding size to topic count; counts are already available via `topicCount`/`messageCount` if a guard/warning is later desired.
- **Self-contained YAML emitter correctness** → Isolated to the YAML path (JSON export is unaffected) and covered by unit tests; only needs to handle the small value space of our export model plus verbatim string payloads.
- **Non-UTF8 / binary payloads** → Represent payload as its existing `dataString`; binary may be lossy. Acceptable: matches current single-message copy behavior.
- **Inconsistent snapshot during live updates** → Snapshot is taken at action time on the current tree state; minor races are acceptable for an export feature.
- **iOS vs macOS export UI differ** (`fileExporter`/share sheet vs. save panel) → Use the same SwiftUI `.fileExporter` already used in the app to keep one code path.

## Migration Plan

Additive feature, no data migration. Deploy with the app release. Rollback = remove the menu actions and the export code; no new dependency and no persisted state are affected.

## Open Questions

- Payload representation: **Resolved** — the payload is preserved verbatim; a JSON message stays JSON even in a YAML export, never restructured.
- Should the selected topic's own message be included when it is an intermediate node with no payload? (Default: include only topics that have a message.)

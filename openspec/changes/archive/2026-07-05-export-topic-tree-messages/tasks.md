## 2. Export model & serialization (Common)

- [x] 2.1 Add `TopicMessageExport` and `TopicTreeExport` `Codable` structs under `src/Common/model`
- [x] 2.2 Implement subtree collection: from a `TopicTree` node, gather `recusiveAllMessages`, take `messages.last` per node, skip nodes without messages, map to `TopicMessageExport` (qualified topic, payload, retain, qos, ISO-8601 timestamp)
- [x] 2.3 Preserve the payload verbatim: keep text as the raw string (never re-serialized), Base64-encode binary payloads with a `payloadEncoding` marker; sort entries by qualified topic for deterministic output
- [x] 2.4 Implement JSON serialization using `JSONEncoder` with `.prettyPrinted` + `.sortedKeys` (mirroring `BrokerExportModel.encode()`)
- [x] 2.5 Implement YAML serialization with a self-contained YAML emitter in `Common` (no external dependency); handle scalar quoting, block-literal (`|-`) scalars for verbatim string payloads, null, and nested collections
- [x] 2.6 Expose a small serializer API returning `String`/`Data` for a given node and format (JSON/YAML)

## 3. UI actions

- [x] 3.1 Add "Copy subtree as JSON" and "Copy subtree as YAML" actions to the topic context menu in `TopicTreeView.swift` (TreeNodeCellView), using `Pasteboard.copy`
- [x] 3.2 Add the same copy actions to `TopicCellView.swift` context menu
- [x] 3.3 Add "Export subtree…" (JSON/YAML) using the `TextFileDocument` + `.fileExporter` pattern from `MessageDetailsJsonView.swift`, with a default filename derived (sanitized) from the topic name

## 4. Tests

- [x] 4.1 Unit test subtree collection: descendants included, message-less topics skipped, leaf topic yields single entry
- [x] 4.2 Unit test JSON output is valid and byte-stable across two runs of an unchanged snapshot
- [x] 4.3 Unit test YAML output is valid and represents the same data as JSON
- [x] 4.4 Unit test payload handling: JSON stays verbatim (block-literal in YAML), binary is Base64-encoded with marker, text omits the marker

## 5. Verification

- [x] 5.1 Manually verify copy-to-clipboard (JSON & YAML) on iOS and macOS
- [x] 5.2 Manually verify file export (JSON & YAML) produces correctly named, valid files on iOS and macOS
- [x] 5.3 Run `openspec validate export-topic-tree-messages` and the project test suite

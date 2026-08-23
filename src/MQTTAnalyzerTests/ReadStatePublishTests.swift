import XCTest
import Combine
@testable import MQTTAnalyzer

/// Every message marks its topic and all of its parents unread. The sidebar
/// observes the root, so a publish there re-renders the whole topic list — it
/// must not happen for messages that change nothing.
class ReadStatePublishTests: XCTestCase {

	private var cancellable: AnyCancellable?

	private func publish(_ text: String, to topic: String, on root: TopicTree) {
		_ = root.addMessage(metadata: MsgMetadata.stub(), payload: MsgPayload.from(text: text), to: topic)
	}

	func testMessagesOnAnUnreadTopicDoNotPublishOnTheRoot() {
		let root = TopicTree()
		publish("first", to: "home/room/device/state", on: root)

		var publishes = 0
		cancellable = root.objectWillChange.sink { _ in publishes += 1 }

		for i in 0..<200 {
			publish("value \(i)", to: "home/room/device/state", on: root)
		}

		print("ROOT-PUBLISHES: \(publishes) for 200 messages on a known topic")

		// The first message marks the topic unread; the rest change nothing
		XCTAssertLessThanOrEqual(publishes, 2)
	}

	func testReadStateStillPropagates() {
		let root = TopicTree()
		publish("a", to: "home/room/device/state", on: root)

		let node = root.getTopic(topic: "home/room/device/state")!
		XCTAssertFalse(node.readState.read)
		XCTAssertFalse(root.getTopic(topic: "home")!.readState.read)

		root.markRead()
		XCTAssertTrue(node.readState.read)
		XCTAssertTrue(root.getTopic(topic: "home")!.readState.read)

		publish("b", to: "home/room/device/state", on: root)
		XCTAssertFalse(node.readState.read)
		XCTAssertFalse(root.getTopic(topic: "home")!.readState.read, "parents are marked unread again")
	}
}

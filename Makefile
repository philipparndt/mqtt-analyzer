.PHONY: screenshots screenshots-refresh screenshots-mac screenshots-mac-messages publish publish-skip-tests test test-ui release-brew help

help:
	@echo "Available targets:"
	@echo "  screenshots            - Create screenshots for App Store (dark and light mode)"
	@echo "  screenshots-refresh    - Create screenshots and refresh device frames"
	@echo "  screenshots-mac        - Launch macOS app with Example broker for manual screenshots"
	@echo "  screenshots-mac-messages - Publish example messages to test broker (requires mosquitto)"
	@echo "  publish                - Build and publish to App Store (with tests)"
	@echo "  publish-skip-tests     - Build and publish to App Store (without tests)"
	@echo "  test                   - Run unit tests"
	@echo "  test-ui                - Run UI tests"
	@echo "  test-integration       - Run integration tests"
	@echo "  release-brew TAG=v1.0  - Release to Homebrew tap (requires: Developer ID cert, notarytool profile, gh CLI)"

screenshots:
	./scripts/create-screenshots.sh

screenshots-refresh:
	./scripts/create-screenshots.sh --refresh-frames

screenshots-mac:
	@echo "Building macOS app..."
	cd src && xcodebuild build \
		-workspace MQTTAnalyzer.xcworkspace \
		-scheme MQTTAnalyzer-macOS \
		-configuration Debug \
		-derivedDataPath build/DerivedData-macOS \
		-quiet
	@echo "Launching app with Example broker..."
	@echo "After connecting, run 'make screenshots-mac-messages' to publish example data"
	@-killall MQTTAnalyzer 2>/dev/null || true
	@sleep 0.5
	@open "src/build/DerivedData-macOS/Build/Products/Debug/MQTTAnalyzer.app" --args --ui-testing --no-welcome
	@sleep 1
	@osascript -e 'tell application "System Events" to tell process "MQTTAnalyzer" to set position of window 1 to {0, 0}' \
		-e 'tell application "System Events" to tell process "MQTTAnalyzer" to set size of window 1 to {1200, 720}'

screenshots-mac-messages:
	@./scripts/publish-example-messages.sh

publish:
	./scripts/publish.sh

publish-skip-tests:
	./scripts/publish-skip-tests.sh

test:
	cd src && xcodebuild test \
		-workspace MQTTAnalyzer.xcworkspace \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-testPlan UnitTestPlan

test-ui:
	cd src && xcodebuild test \
		-workspace MQTTAnalyzer.xcworkspace \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-only-testing:MQTTAnalyzerUITests

release-brew:
ifndef TAG
	$(error TAG is required. Usage: make release-brew TAG=v3.0.0)
endif
	./scripts/release-brew.sh $(TAG)

test-integration:
	cd src && xcodebuild test \
		-workspace MQTTAnalyzer.xcworkspace \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-only-testing:MQTTAnalyzerIntegrationTests

.PHONY: screenshots screenshots-refresh publish publish-skip-tests test test-ui help

help:
	@echo "Available targets:"
	@echo "  screenshots        - Create screenshots for App Store (dark and light mode)"
	@echo "  screenshots-refresh - Create screenshots and refresh device frames"
	@echo "  publish            - Build and publish to App Store (with tests)"
	@echo "  publish-skip-tests - Build and publish to App Store (without tests)"
	@echo "  test               - Run unit tests"
	@echo "  test-ui            - Run UI tests"
	@echo "  test-integration   - Run integration tests"

screenshots:
	./scripts/create-screenshots.sh

screenshots-refresh:
	./scripts/create-screenshots.sh --refresh-frames

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

test-integration:
	cd src && xcodebuild test \
		-workspace MQTTAnalyzer.xcworkspace \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-only-testing:MQTTAnalyzerIntegrationTests

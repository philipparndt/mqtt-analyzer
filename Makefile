.PHONY: screenshots screenshots-refresh screenshots-mac screenshots-mac-messages publish-examples publish publish-skip-tests test test-ui release-brew bump-major bump-minor bump-patch help

PBXPROJ := src/MQTTAnalyzer.xcodeproj/project.pbxproj
CURRENT_VERSION := $(shell grep -m1 'MARKETING_VERSION' $(PBXPROJ) | sed 's/.*= *\(.*\);/\1/')

help:
	@echo "Available targets:"
	@echo "  screenshots            - Create screenshots for App Store (dark and light mode)"
	@echo "  screenshots-refresh    - Create screenshots and refresh device frames"
	@echo "  screenshots-mac        - Launch macOS app with Example broker for manual screenshots"
	@echo "  screenshots-mac-messages - Publish retained example messages to test broker (uses mqtt-analyzer CLI)"
	@echo "  publish-examples         - Publish retained example messages to test broker (uses mqtt-analyzer CLI)"
	@echo "  publish                - Build and publish to App Store (with tests)"
	@echo "  publish-skip-tests     - Build and publish to App Store (without tests)"
	@echo "  test                   - Run unit tests"
	@echo "  test-ui                - Run UI tests"
	@echo "  test-integration       - Run integration tests"
	@echo "  release-brew           - Release to Homebrew tap using current version (or TAG=v1.0 to override)"
	@echo "  bump-major             - Bump major version (X.0.0)"
	@echo "  bump-minor             - Bump minor version (x.X.0)"
	@echo "  bump-patch             - Bump patch version (x.x.X)"

screenshots:
	./scripts/create-screenshots.sh

screenshots-refresh:
	./scripts/create-screenshots.sh --refresh-frames

screenshots-mac:
	@echo "Building macOS app..."
	cd src && xcodebuild build \
		-project MQTTAnalyzer.xcodeproj \
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

screenshots-mac-messages: publish-examples

publish-examples:
	@./scripts/publish-example-messages.sh

publish:
	./scripts/publish.sh

publish-skip-tests:
	./scripts/publish-skip-tests.sh

test:
	cd src && xcodebuild test \
		-project MQTTAnalyzer.xcodeproj \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-testPlan UnitTestPlan

test-ui:
	cd src && xcodebuild test \
		-project MQTTAnalyzer.xcodeproj \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-only-testing:MQTTAnalyzerUITests

release-brew:
	@TAG=$${TAG:-v$(CURRENT_VERSION)}; \
	if git tag -l "$$TAG" | grep -q "$$TAG"; then \
		echo "Error: Tag $$TAG already exists. Bump the version first with make bump-major/bump-minor/bump-patch."; \
		exit 1; \
	fi; \
	./scripts/release-brew.sh $$TAG

test-integration:
	cd src && xcodebuild test \
		-project MQTTAnalyzer.xcodeproj \
		-scheme MQTTAnalyzer \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-only-testing:MQTTAnalyzerIntegrationTests

bump-major:
	@MAJOR=$$(echo $(CURRENT_VERSION) | cut -d. -f1); \
	NEW_VERSION=$$((MAJOR + 1)).0.0; \
	/usr/bin/sed -i '' "s/MARKETING_VERSION = $(CURRENT_VERSION)/MARKETING_VERSION = $$NEW_VERSION/g" $(PBXPROJ); \
	echo "Version bumped: $(CURRENT_VERSION) -> $$NEW_VERSION"

bump-minor:
	@MINOR=$$(echo $(CURRENT_VERSION) | cut -d. -f2); \
	MAJOR=$$(echo $(CURRENT_VERSION) | cut -d. -f1); \
	NEW_VERSION=$$MAJOR.$$((MINOR + 1)).0; \
	/usr/bin/sed -i '' "s/MARKETING_VERSION = $(CURRENT_VERSION)/MARKETING_VERSION = $$NEW_VERSION/g" $(PBXPROJ); \
	echo "Version bumped: $(CURRENT_VERSION) -> $$NEW_VERSION"

bump-patch:
	@PATCH=$$(echo $(CURRENT_VERSION) | cut -d. -f3); \
	MAJOR=$$(echo $(CURRENT_VERSION) | cut -d. -f1); \
	MINOR=$$(echo $(CURRENT_VERSION) | cut -d. -f2); \
	NEW_VERSION=$$MAJOR.$$MINOR.$$((PATCH + 1)); \
	/usr/bin/sed -i '' "s/MARKETING_VERSION = $(CURRENT_VERSION)/MARKETING_VERSION = $$NEW_VERSION/g" $(PBXPROJ); \
	echo "Version bumped: $(CURRENT_VERSION) -> $$NEW_VERSION"

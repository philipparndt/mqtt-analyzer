.PHONY: help install lint build test clean mqtt-service mqtt-service-down open

# Default target
help:
	@echo "Available targets:"
	@echo "  install          - Install CocoaPods dependencies"
	@echo "  lint             - Run SwiftLint"
	@echo "  build            - Build the app for iOS simulator"
	@echo "  test             - Run unit tests"
	@echo "  clean            - Clean build artifacts"
	@echo "  mqtt-service     - Start MQTT stub service (Docker)"
	@echo "  mqtt-service-down- Stop MQTT stub service"
	@echo "  open             - Open Xcode workspace"

# Configuration
WORKSPACE = src/MQTTAnalyzer.xcworkspace
SCHEME = MQTTAnalyzer
SIMULATOR = platform=iOS Simulator,name=iPhone 15,OS=latest

# Install dependencies
install:
	cd src && pod install

# Run SwiftLint
lint:
	cd src && swiftlint

# Build for simulator
build:
	xcodebuild build \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination '$(SIMULATOR)'

# Run tests
test:
	xcodebuild test \
		-enableCodeCoverage YES \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination '$(SIMULATOR)'

# Clean build artifacts
clean:
	xcodebuild clean \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME)
	rm -rf src/build

# Start MQTT stub service
mqtt-service:
	cd mqtt-stub-service && docker-compose up -d

# Stop MQTT stub service
mqtt-service-down:
	cd mqtt-stub-service && docker-compose down

# Open Xcode workspace
open:
	open $(WORKSPACE)

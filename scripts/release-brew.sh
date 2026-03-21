#!/bin/bash
set -euo pipefail

# Release MQTTAnalyzer to Homebrew tap
# Usage: ./scripts/release-brew.sh <tag>
# Example: ./scripts/release-brew.sh v3.0.0

TAG="${1:-}"
if [ -z "$TAG" ]; then
    echo "Usage: $0 <tag>"
    echo "Example: $0 v3.0.0"
    exit 1
fi

APP_NAME="MQTTAnalyzer"
SCHEME="MQTTAnalyzer-macOS"
WORKSPACE="src/MQTTAnalyzer.xcworkspace"
ARCHIVE_PATH="build/brew/${APP_NAME}.xcarchive"
EXPORT_PATH="build/brew/export"
EXPORT_OPTIONS_ENC="scripts/ExportOptions-brew.plist"
EXPORT_OPTIONS="scripts/ExportOptions-brew.plist.dec"
ZIP_NAME="${APP_NAME}-${TAG}.zip"
ZIP_PATH="build/brew/${ZIP_NAME}"
GITHUB_REPO="philipparndt/mqtt-analyzer"
HOMEBREW_TAP_REPO="philipparndt/homebrew-mqtt-analyzer"

echo "=== Releasing ${APP_NAME} ${TAG} to Homebrew ==="

# Step 1: Decrypt export options
echo ""
echo "--- Decrypting export options ---"
sops decrypt "${EXPORT_OPTIONS_ENC}" > "${EXPORT_OPTIONS}"
trap 'rm -f "${EXPORT_OPTIONS}"' EXIT
echo "Decrypted to ${EXPORT_OPTIONS}"

# Step 2: Clean build directory
echo ""
echo "--- Cleaning build directory ---"
rm -rf build/brew
mkdir -p build/brew

# Step 3: Archive
echo ""
echo "--- Archiving ${APP_NAME} (macOS) ---"
xcodebuild archive \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -destination "generic/platform=macOS" \
    -archivePath "${ARCHIVE_PATH}" \
    OTHER_CODE_SIGN_FLAGS="--options=runtime" \
    -quiet

echo "Archive created at ${ARCHIVE_PATH}"

# Step 4: Export with Developer ID signing
echo ""
echo "--- Exporting with Developer ID signing ---"
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    -quiet

echo "Exported to ${EXPORT_PATH}"

# Step 5: Notarize
echo ""
echo "--- Notarizing ---"
ZIP_FOR_NOTARIZATION="build/brew/${APP_NAME}-notarize.zip"
ditto -c -k --keepParent "${EXPORT_PATH}/${APP_NAME}.app" "${ZIP_FOR_NOTARIZATION}"

NOTARY_OUTPUT=$(xcrun notarytool submit "${ZIP_FOR_NOTARIZATION}" \
    --keychain-profile "notarytool" \
    --wait 2>&1)
echo "${NOTARY_OUTPUT}"

if echo "${NOTARY_OUTPUT}" | grep -q "status: Invalid"; then
    SUBMISSION_ID=$(echo "${NOTARY_OUTPUT}" | grep "id:" | head -1 | awk '{print $2}')
    echo "Notarization failed. Fetching log..."
    xcrun notarytool log "${SUBMISSION_ID}" --keychain-profile "notarytool"
    exit 1
fi

# Step 6: Staple the notarization ticket
echo ""
echo "--- Stapling notarization ticket ---"
xcrun stapler staple "${EXPORT_PATH}/${APP_NAME}.app"

# Step 7: Create final ZIP for distribution
echo ""
echo "--- Creating distribution ZIP ---"
ditto -c -k --keepParent "${EXPORT_PATH}/${APP_NAME}.app" "${ZIP_PATH}"

SHA256=$(shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')
echo "SHA256: ${SHA256}"

# Step 8: Create GitHub release
echo ""
echo "--- Creating GitHub release ${TAG} ---"
gh release create "${TAG}" "${ZIP_PATH}" \
    --repo "${GITHUB_REPO}" \
    --title "${APP_NAME} ${TAG}" \
    --generate-notes

DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${TAG}/${ZIP_NAME}"
echo "Download URL: ${DOWNLOAD_URL}"

# Step 9: Update Homebrew cask formula
echo ""
echo "--- Updating Homebrew cask formula ---"

CASK_CONTENT="cask \"mqtt-analyzer\" do
  version \"${TAG#v}\"
  sha256 \"${SHA256}\"

  url \"https://github.com/${GITHUB_REPO}/releases/download/${TAG}/${APP_NAME}-${TAG}.zip\"
  name \"MQTT Analyzer\"
  desc \"MQTT client for monitoring and debugging MQTT brokers\"
  homepage \"https://github.com/${GITHUB_REPO}\"

  depends_on macos: \">= :ventura\"

  app \"${APP_NAME}.app\"

  zap trash: [
    \"~/Library/Containers/de.rnd7.MQTTAnalyzer\",
    \"~/Library/Group Containers/group.de.rnd7.mqttanalyzer\",
  ]
end
"

HOMEBREW_TAP_DIR=$(mktemp -d)
echo "Cloning Homebrew tap to ${HOMEBREW_TAP_DIR}..."
gh repo clone "${HOMEBREW_TAP_REPO}" "${HOMEBREW_TAP_DIR}"

mkdir -p "${HOMEBREW_TAP_DIR}/Casks"
echo "${CASK_CONTENT}" > "${HOMEBREW_TAP_DIR}/Casks/mqtt-analyzer.rb"

cd "${HOMEBREW_TAP_DIR}"
git add Casks/mqtt-analyzer.rb
git commit -m "Update mqtt-analyzer to ${TAG}"
git push
cd -

rm -rf "${HOMEBREW_TAP_DIR}"

echo ""
echo "=== Release complete ==="
echo "Install with: brew install philipparndt/mqtt-analyzer/mqtt-analyzer"
echo "Or: brew tap philipparndt/mqtt-analyzer && brew install mqtt-analyzer"

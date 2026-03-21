# Developer notes

| Description           | Command                   |
| --------------------- | ------------------------- |
| Run unit tests        | `make test`               |
| Run UI tests          | `make test-ui`            |
| Run integration tests | `make test-integration`   |
| Set new version       | `./set-version.sh 2.12.0` |

## Homebrew release setup

Releasing to Homebrew requires a **Developer ID Application** certificate, a provisioning profile, and notarization credentials. This is done locally (not in CI) to keep the developer identity out of public repositories.

### Prerequisites

- An [Apple Developer Program](https://developer.apple.com/programs/) membership
- [Xcode](https://developer.apple.com/xcode/) installed
- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- [sops](https://github.com/getsops/sops) installed (for decrypting export options)
- The `age` key used for sops decryption

### Step 1: Create a Developer ID Application certificate

1. Go to [developer.apple.com](https://developer.apple.com) > **Certificates, Identifiers & Profiles** > **Certificates**
2. Click **+** to create a new certificate
3. Scroll down to the **Services** section and select **Developer ID Application**
   - Do **not** select "Apple Distribution" (that is for App Store only)
   - Do **not** select "Developer ID Installer" (that is for `.pkg` signing only)
4. Create a Certificate Signing Request (CSR) using Keychain Access:
   - Open **Keychain Access** > **Certificate Assistant** > **Request a Certificate From a Certificate Authority**
   - Enter your email, select **Saved to disk**, and save the `.certSigningRequest` file
5. Upload the CSR on the Apple Developer portal and click **Continue**
6. Download the generated `.cer` file and double-click it to install it in your Keychain

Verify the certificate is installed:

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### Step 2: Create a Developer ID provisioning profile

1. Go to [developer.apple.com](https://developer.apple.com) > **Certificates, Identifiers & Profiles** > **Profiles**
2. Click **+** to create a new profile
3. Under **Distribution**, select **Developer ID**
4. Select the App ID `de.rnd7.MQTTAnalyzer`
5. Select the Developer ID Application certificate created in Step 1
6. Name the profile (e.g., "MQTTAnalyzer Homebrew") and click **Generate**
7. Download the `.provisionprofile` file
8. Copy it to the Xcode provisioning profiles directory:

```bash
UUID=$(security cms -D -i ~/Downloads/YourProfile.provisionprofile | grep -A1 "<key>UUID</key>" | tail -1 | sed 's/.*<string>//;s/<\/string>//')
cp ~/Downloads/YourProfile.provisionprofile ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/"${UUID}.provisionprofile"
```

### Step 3: Store notarization credentials

Apple requires notarization for all Developer ID signed apps. Store your credentials in the keychain so the release script can use them non-interactively:

```bash
xcrun notarytool store-credentials "notarytool" --apple-id <your-apple-id> --team-id 643R6YSRER
```

This will prompt for an **app-specific password** (not your regular Apple ID password). Generate one at [appleid.apple.com](https://appleid.apple.com) > **Sign-In and Security** > **App-Specific Passwords**.

### Step 4: Release

```bash
make release-brew TAG=v3.1.0
```

This will:
1. Decrypt the export options using sops
2. Archive the macOS app with hardened runtime
3. Export with Developer ID signing
4. Notarize the app with Apple
5. Staple the notarization ticket
6. Create a GitHub release with the signed ZIP
7. Update the Homebrew cask formula in the [homebrew-mqtt-analyzer](https://github.com/philipparndt/homebrew-mqtt-analyzer) tap

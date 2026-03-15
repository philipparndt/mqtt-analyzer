//
//  CertificatePickerView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A simplified certificate file picker using native file importers.
/// Handles iOS and macOS platforms properly.
/// Note: For P12 files, validation is handled by the parent view (CertificateAuthenticationView)
/// since it requires the password. This picker only validates non-P12 files (Server CA, etc.)
struct CertificatePickerView: View { // swiftlint:disable:this type_body_length
    let label: String
    @Binding var file: CertificateFile?
    let type: CertificateFileType
    var password: String = ""
    var alwaysUseCloud: Bool = false  // For Server CA, always use iCloud

    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var detailsMessage: String?
    @State private var showError = false
    @State private var fileStatus: FileStatus = .exists

    // For storage location choice dialog
    @State private var showStorageChoice = false
    @State private var pendingFileURL: URL?

    private enum FileStatus {
        case exists
        case missing
        case differentCertificate
    }

    /// Whether to show validation status in this picker
    /// P12 validation is handled by parent view with password
    private var showValidationStatus: Bool {
        type != .p12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.headline)

                Spacer()

                if let selectedFile = file {
                    selectedFileView(selectedFile)
                } else {
                    selectButton
                }
            }

            // Show warnings based on file status
            if file != nil {
                switch fileStatus {
                case .missing:
                    missingFileWarning
                case .differentCertificate:
                    differentCertificateWarning
                case .exists:
                    EmptyView()
                }
            }

            // Only show validation status for non-P12 types when file exists
            if showValidationStatus && fileStatus == .exists {
                if let success = successMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let details = detailsMessage {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let error = errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
        .confirmationDialog(
            "Where should this certificate be stored?",
            isPresented: $showStorageChoice,
            titleVisibility: .visible
        ) {
            Button("This Device Only") {
                if let url = pendingFileURL {
                    completeImport(url: url, location: .local)
                }
            }
            Button("iCloud (sync to all devices)") {
                if let url = pendingFileURL {
                    completeImport(url: url, location: .cloud)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingFileURL = nil
            }
        } message: {
            Text("Local is more secure for certificates with private keys. iCloud syncs across devices but stores the private key in the cloud.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            checkFileStatus()
            // Validate existing file on appear (for Server CA files)
            if showValidationStatus, let selectedFile = file, fileStatus == .exists {
                validateExistingFile(selectedFile)
            }
        }
        .onChange(of: file) { _, _ in
            checkFileStatus()
        }
    }

    private var missingFileWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Certificate not available on this device")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Text("This certificate was configured on another device.")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import Certificate")
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var differentCertificateWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Different certificate on this device")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Text("A file with the same name exists but it's not the same certificate. Import the correct certificate.")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import Correct Certificate")
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    private func checkFileStatus() {
        guard let selectedFile = file else {
            fileStatus = .exists
            return
        }

        if selectedFile.exists() {
            fileStatus = .exists
        } else if selectedFile.existsButDifferent() {
            fileStatus = .differentCertificate
        } else {
            fileStatus = .missing
        }
    }

    private func validateExistingFile(_ selectedFile: CertificateFile) {
        do {
            var fileURL = try selectedFile.getBaseUrl(certificate: selectedFile)
            fileURL.appendPathComponent(selectedFile.name)
            let result = validateCertificateFile(url: fileURL, type: type, password: password)

            if result.isValid {
                successMessage = result.message
                detailsMessage = result.details
                errorMessage = nil
            } else {
                errorMessage = result.message
                detailsMessage = result.details
                successMessage = nil
            }
        } catch {
            errorMessage = "Cannot access certificate file"
            successMessage = nil
            detailsMessage = nil
        }
    }

    private var selectButton: some View {
        Button {
            showFilePicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "doc.badge.plus")
                Text("Select")
            }
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
    }

    private func selectedFileView(_ selectedFile: CertificateFile) -> some View {
        HStack(spacing: 8) {
            // Show cloud icon for iCloud storage, document icon for local
            Image(systemName: selectedFile.location == .cloud ? "icloud.fill" : "doc.fill")
                .foregroundColor(selectedFile.location == .cloud ? .blue : .accentColor)

            Text(selectedFile.name)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Button(action: clearSelection) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var allowedTypes: [UTType] {
        switch type {
        case .p12:
            var types: [UTType] = [.pkcs12]
            if let pfx = UTType(filenameExtension: "pfx") { types.append(pfx) }
            return types
        case .serverCA, .client:
            var types: [UTType] = [.x509Certificate]
            if let crt = UTType(filenameExtension: "crt") { types.append(crt) }
            if let pem = UTType(filenameExtension: "pem") { types.append(pem) }
            // Also allow P12 for Server CA
            if type == .serverCA {
                types.append(.pkcs12)
                if let pfx = UTType(filenameExtension: "pfx") { types.append(pfx) }
            }
            return types
        case .clientKey:
            var types: [UTType] = []
            if let key = UTType(filenameExtension: "key") { types.append(key) }
            if let pem = UTType(filenameExtension: "pem") { types.append(pem) }
            return types.isEmpty ? [.data] : types
        case .undefined:
            return [.pkcs12, .x509Certificate]
        }
    }

    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Access the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access the selected file"
                showError = true
                return
            }

            // For Server CA or when alwaysUseCloud is set, import directly to iCloud
            if alwaysUseCloud {
                completeImport(url: url, location: .cloud)
            } else {
                // Show choice dialog for client certificates
                pendingFileURL = url
                showStorageChoice = true
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func completeImport(url: URL, location: CertificateLocation) {
        defer {
            url.stopAccessingSecurityScopedResource()
            pendingFileURL = nil
        }

        // Compute hash before copying
        let hash = computeFileHash(url: url)

        // Validate the certificate before copying
        let validationResult = validateCertificateFile(url: url, type: type, password: password)

        // For client P12 without password, skip validation (will be validated when password is entered)
        let skipValidation = type == .p12 && password.isEmpty

        if !skipValidation && !validationResult.isValid {
            errorMessage = validationResult.message
            detailsMessage = validationResult.details
            successMessage = nil
            // Still copy the file so user can fix the issue (e.g., enter password)
        }

        // Copy to documents based on storage location
        // The returned filename may differ from the original if a conflict was resolved
        if let resultFilename = copyToDocuments(url: url, location: location, hash: hash) {
            var newFile = CertificateFile(
                name: resultFilename,
                location: location,
                type: type
            )
            newFile.fileHash = hash
            file = newFile
            fileStatus = .exists

            if validationResult.isValid {
                successMessage = validationResult.message
                detailsMessage = validationResult.details
                errorMessage = nil
            } else if skipValidation {
                // P12 without password - show neutral message
                successMessage = nil
                detailsMessage = nil
                errorMessage = nil
            }
        }
    }

    /// Copies the file to the appropriate documents directory
    /// - Returns: The resulting filename if successful, nil otherwise
    private func copyToDocuments(url: URL, location: CertificateLocation, hash: String?) -> String? {
        if location == .cloud {
            return copyToCloudDocuments(url: url, hash: hash)
        } else {
            return copyToLocalDocuments(url: url)
        }
    }

    private func copyToLocalDocuments(url: URL) -> String? {
        let fileManager = FileManager.default

        guard let localDocumentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            errorMessage = "Cannot access local documents directory"
            showError = true
            return nil
        }

        let destinationURL = localDocumentsURL.appendingPathComponent(url.lastPathComponent)

        // Check if source and target are the same file (already in local documents)
        if url.standardizedFileURL == destinationURL.standardizedFileURL {
            return url.lastPathComponent
        }

        do {
            // Remove existing file if present (local storage is per-app, so overwriting is fine)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            // Copy the file
            try fileManager.copyItem(at: url, to: destinationURL)
            return url.lastPathComponent

        } catch {
            errorMessage = "Failed to copy file: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }

    private func copyToCloudDocuments(url: URL, hash: String?) -> String? {
        guard CloudDataManager.instance.isCloudEnabled() else {
            errorMessage = "iCloud is not available. Please enable iCloud Drive in Settings."
            showError = true
            return nil
        }

        if let resultFilename = CloudDataManager.instance.copyFileToCloud(file: url, sourceHash: hash) {
            return resultFilename
        } else {
            errorMessage = "Failed to copy file to iCloud"
            showError = true
            return nil
        }
    }

    private func clearSelection() {
        file = nil
        errorMessage = nil
        successMessage = nil
        detailsMessage = nil
    }
}

// MARK: - Help Sheet

struct CertificateHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpSection(
                        title: "What is a PKCS#12 file?",
                        content: """
                            A PKCS#12 file (.p12 or .pfx) is a secure container that \
                            bundles your client certificate and private key together, \
                            protected by a password.
                            """
                    )

                    helpSection(
                        title: "Creating a PKCS#12 file",
                        content: """
                            If you have separate certificate (.crt) and key (.key) \
                            files, combine them using OpenSSL:
                            """
                    )

                    codeBlock("""
                        openssl pkcs12 -export \\
                          -in client.crt \\
                          -inkey client.key \\
                          -out client.p12
                        """)

                    helpSection(
                        title: "Including a CA certificate",
                        content: "To include the CA certificate chain:"
                    )

                    codeBlock("""
                        openssl pkcs12 -export \\
                          -in client.crt \\
                          -inkey client.key \\
                          -certfile ca.crt \\
                          -out client.p12
                        """)

                    helpSection(
                        title: "Verifying your certificate",
                        content: "To verify the contents of a PKCS#12 file:"
                    )

                    codeBlock("openssl pkcs12 -info -in client.p12")

                    helpSection(
                        title: "Common issues",
                        content: """
                            Wrong password: The password must match the one used \
                            when creating the .p12 file.

                            File not found: Ensure the file was successfully imported.

                            Connection refused: Verify the certificate is trusted \
                            by your MQTT broker.
                            """
                    )

                    Divider()
                        .padding(.vertical, 8)

                    helpSection(
                        title: "More information",
                        content: "For detailed instructions and examples, visit the online documentation:"
                    )

                    Link(destination: URL(string: "https://github.com/philipparndt/mqtt-analyzer/blob/master/Docs/examples/client-certs/README.md")!) {
                        HStack {
                            Image(systemName: "book")
                            Text("Client Certificates Documentation")
                        }
                        .foregroundColor(.accentColor)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Certificate Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }

    private func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private func codeBlock(_ code: String) -> some View {
        HStack {
            Text(code)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)

            Spacer()
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

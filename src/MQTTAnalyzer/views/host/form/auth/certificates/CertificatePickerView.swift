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
struct CertificatePickerView: View {
    let label: String
    @Binding var file: CertificateFile?
    let type: CertificateFileType

    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var showError = false

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

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private var selectButton: some View {
        Button(action: { showFilePicker = true }) {
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
            Image(systemName: "doc.fill")
                .foregroundColor(.accentColor)

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
            return [.pkcs12]
        case .serverCA, .client:
            var types: [UTType] = [.x509Certificate]
            if let crt = UTType(filenameExtension: "crt") { types.append(crt) }
            if let pem = UTType(filenameExtension: "pem") { types.append(pem) }
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

            defer { url.stopAccessingSecurityScopedResource() }

            // Copy to local documents
            if copyToLocalDocuments(url: url) {
                file = CertificateFile(
                    name: url.lastPathComponent,
                    location: .local,
                    type: type
                )
                errorMessage = nil
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func copyToLocalDocuments(url: URL) -> Bool {
        let fileManager = FileManager.default

        guard let localDocumentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            errorMessage = "Cannot access local documents directory"
            showError = true
            return false
        }

        let destinationURL = localDocumentsURL.appendingPathComponent(url.lastPathComponent)

        do {
            // Remove existing file if present
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            // Copy the file
            try fileManager.copyItem(at: url, to: destinationURL)
            return true

        } catch {
            errorMessage = "Failed to copy file: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    private func clearSelection() {
        file = nil
        errorMessage = nil
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

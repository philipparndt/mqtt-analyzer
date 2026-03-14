//
//  CertificateAuthenticationView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

/// mTLS client certificate authentication view
struct CertificateAuthenticationView: View {
    @Binding var host: HostFormModel
    @Binding var showHelp: Bool

    @State private var p12ValidationResult: CertificateValidationResult?

    /// Combined key for certificate + password to trigger validation
    private var validationKey: String {
        "\(host.certP12?.name ?? ""):\(host.certClientKeyPassword)"
    }

    var body: some View {
        Group {
            CertificatePickerView(
                label: "Client PKCS#12",
                file: $host.certP12,
                type: .p12,
                password: host.certClientKeyPassword
            )

            HStack {
                Text("Password")
                    .font(.headline)

                Spacer()

                SecureField("Certificate password", text: $host.certClientKeyPassword)
                    .disableAutocorrection(true)
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .font(.body)
            }

            // Validation status
            validationStatusView

            if host.certP12 == nil {
                Text("Client certificate for mTLS authentication")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button {
                showHelp = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("How to create certificates")
                }
                .foregroundColor(.accentColor)
                .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            validateP12()
        }
        .onChange(of: validationKey) { _, _ in
            validateP12()
        }
    }

    @ViewBuilder
    private var validationStatusView: some View {
        if let result = p12ValidationResult {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.isValid ? .green : .orange)
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(result.isValid ? .secondary : .red)
                }
                if let details = result.details {
                    Text(details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        } else if host.certP12 != nil && host.certClientKeyPassword.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Password is required for PKCS#12 files")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func validateP12() {
        guard let certFile = host.certP12, !host.certClientKeyPassword.isEmpty else {
            p12ValidationResult = nil
            return
        }

        let fileManager = FileManager.default
        guard let localDocumentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            p12ValidationResult = .invalid("Cannot access documents")
            return
        }

        let fileURL = localDocumentsURL.appendingPathComponent(certFile.name)
        p12ValidationResult = validateCertificateFile(url: fileURL, type: .p12, password: host.certClientKeyPassword)
    }
}

//
//  CertificateAuthenticationView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-02-25.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import SwiftUI

struct CertificateAuthenticationView: View {
    @Binding var host: HostFormModel
    @State private var showHelp = false

    var body: some View {
        Group {
            CertificatePickerView(
                label: "Client PKCS#12",
                file: $host.certP12,
                type: .p12
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

            if host.certP12 != nil && host.certClientKeyPassword.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Password is required for PKCS#12 files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: { showHelp = true }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("How to create certificates")
                }
                .foregroundColor(.accentColor)
                .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showHelp) {
            CertificateHelpSheet()
        }
    }
}

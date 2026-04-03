//
//  CLICommandView.swift
//  MQTTAnalyzer
//
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

#if os(macOS)
import SwiftUI

struct CLICommandView: View {
    let command: String
    let onDismiss: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(systemName: "terminal")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)

                Text("Manual Installation Required")
                    .font(.headline)

                Text("Run this command in your terminal:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Code block
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    ForEach(Array(tokenizeCommand().enumerated()), id: \.offset) { _, token in
                        Text(token.value)
                            .foregroundColor(token.color)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(16)
                .fixedSize()
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            Divider()

            HStack {
                Button("Close") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    CLIInstaller.copyToPasteboard(command)
                    withAnimation {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            copied = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy Command")
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 520)
    }

    private struct ColoredToken {
        let value: String
        let color: Color
    }

    private func tokenizeCommand() -> [ColoredToken] {
        var tokens: [ColoredToken] = []
        tokens.append(ColoredToken(value: "$ ", color: Color(.systemGreen)))

        let chunks = splitPreservingSpaces(command)
        var isFirstWord = true

        for chunk in chunks {
            if chunk.allSatisfy({ $0 == " " }) {
                tokens.append(ColoredToken(value: chunk, color: .primary))
            } else if isFirstWord {
                // "sudo" or the main command
                tokens.append(ColoredToken(value: chunk, color: Color(.systemOrange)))
                isFirstWord = false
            } else if chunk.hasPrefix("-") {
                tokens.append(ColoredToken(value: chunk, color: Color(.systemCyan)))
            } else if chunk.hasPrefix("'") || chunk.hasPrefix("/") {
                tokens.append(ColoredToken(value: chunk, color: Color(.systemYellow)))
            } else {
                // subcommand (ln, rm, etc.)
                tokens.append(ColoredToken(value: chunk, color: Color(.systemGreen)))
            }
        }

        return tokens
    }

    private func splitPreservingSpaces(_ input: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inSpaces = false
        var inQuote = false

        for char in input {
            if char == "'" {
                inQuote.toggle()
                current.append(char)
                continue
            }

            let isSpace = char == " " && !inQuote
            if isSpace != inSpaces && !current.isEmpty {
                result.append(current)
                current = ""
            }
            current.append(char)
            inSpaces = isSpace
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
#endif

//
//  AnsiTextView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2026-03-07.
//  Copyright © 2026 Philipp Arndt. All rights reserved.
//

import SwiftUI

/// A view that renders text with ANSI escape code colors
struct AnsiTextView: View {
    let text: String
    var lineLimit: Int?

    var body: some View {
        Text(parseAnsiText(text))
            .lineLimit(lineLimit)
    }

    private func parseAnsiText(_ input: String) -> AttributedString {
        var result = AttributedString()
        var currentAttributes = AnsiAttributes()

        // Pattern matches ANSI escape sequences: ESC[ followed by params and ending with 'm'
        // ESC can be \x1b, \033, or the literal escape character
        let pattern = #"\x1b\[([0-9;]*)m|\u001b\[([0-9;]*)m"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return AttributedString(input)
        }

        let nsString = input as NSString
        var lastEnd = 0

        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            // Add text before this match with current attributes
            if match.range.location > lastEnd {
                let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let textPart = nsString.substring(with: textRange)
                var attrString = AttributedString(textPart)
                applyAttributes(&attrString, attributes: currentAttributes)
                result.append(attrString)
            }

            // Parse the ANSI codes
            let codesRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            if codesRange.location != NSNotFound {
                let codesString = nsString.substring(with: codesRange)
                currentAttributes = parseAnsiCodes(codesString, current: currentAttributes)
            }

            lastEnd = match.range.location + match.range.length
        }

        // Add remaining text
        if lastEnd < nsString.length {
            let textPart = nsString.substring(from: lastEnd)
            var attrString = AttributedString(textPart)
            applyAttributes(&attrString, attributes: currentAttributes)
            result.append(attrString)
        }

        return result.characters.isEmpty ? AttributedString(input) : result
    }

    private func parseAnsiCodes(_ codesString: String, current: AnsiAttributes) -> AnsiAttributes {
        var attributes = current
        let codes = codesString.split(separator: ";").compactMap { Int($0) }

        if codes.isEmpty {
            // Empty or just ESC[m means reset
            return AnsiAttributes()
        }

        for code in codes {
            switch code {
            case 0:
                attributes = AnsiAttributes()
            case 1:
                attributes.bold = true
            case 2:
                attributes.dim = true
            case 22:
                attributes.bold = false
                attributes.dim = false
            case 30...37:
                attributes.foreground = ansiColor(code - 30, bright: false)
            case 39:
                attributes.foreground = nil
            case 40...47:
                attributes.background = ansiColor(code - 40, bright: false)
            case 49:
                attributes.background = nil
            case 90...97:
                attributes.foreground = ansiColor(code - 90, bright: true)
            case 100...107:
                attributes.background = ansiColor(code - 100, bright: true)
            default:
                break
            }
        }

        return attributes
    }

    private func ansiColor(_ index: Int, bright: Bool) -> Color {
        let colors: [(normal: Color, bright: Color)] = [
            (.black, .gray),                           // 0: black
            (.red, Color(red: 1.0, green: 0.3, blue: 0.3)),     // 1: red
            (.green, Color(red: 0.3, green: 1.0, blue: 0.3)),   // 2: green
            (.yellow, Color(red: 1.0, green: 1.0, blue: 0.3)),  // 3: yellow
            (.blue, Color(red: 0.3, green: 0.5, blue: 1.0)),    // 4: blue
            (.purple, Color(red: 1.0, green: 0.3, blue: 1.0)),  // 5: magenta
            (.cyan, Color(red: 0.3, green: 1.0, blue: 1.0)),    // 6: cyan
            (.white, .white)                           // 7: white
        ]

        guard index >= 0 && index < colors.count else { return .primary }
        return bright ? colors[index].bright : colors[index].normal
    }

    private func applyAttributes(_ string: inout AttributedString, attributes: AnsiAttributes) {
        if let fg = attributes.foreground {
            string.foregroundColor = fg
        }
        if let bg = attributes.background {
            string.backgroundColor = bg
        }
        if attributes.bold {
            string.font = .body.bold()
        }
        if attributes.dim {
            string.foregroundColor = (attributes.foreground ?? .primary).opacity(0.6)
        }
    }
}

private struct AnsiAttributes {
    var foreground: Color?
    var background: Color?
    var bold: Bool = false
    var dim: Bool = false
}

// MARK: - Preview
#if DEBUG
struct AnsiTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 10) {
            AnsiTextView(text: "\u{001b}[0;33m[W][component:157]: Warning message\u{001b}[0m")
            AnsiTextView(text: "\u{001b}[31mRed\u{001b}[0m \u{001b}[32mGreen\u{001b}[0m \u{001b}[34mBlue\u{001b}[0m")
            AnsiTextView(text: "\u{001b}[1;91mBold Bright Red\u{001b}[0m")
            AnsiTextView(text: "No ANSI codes here")
        }
        .padding()
    }
}
#endif

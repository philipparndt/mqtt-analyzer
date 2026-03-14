//
//  PlatformCompat.swift
//  MQTTAnalyzer
//
//  Platform compatibility layer for iOS/macOS
//

import SwiftUI

#if os(macOS)
import AppKit

// MARK: - Clipboard
public enum Pasteboard {
	public static func copy(_ string: String) {
		NSPasteboard.general.clearContents()
		NSPasteboard.general.setString(string, forType: .string)
	}

	public static var string: String? {
		NSPasteboard.general.string(forType: .string)
	}
}

#else
import UIKit

// MARK: - Clipboard
public enum Pasteboard {
	public static func copy(_ string: String) {
		UIPasteboard.general.string = string
	}

	public static var string: String? {
		UIPasteboard.general.string
	}
}

#endif

// MARK: - View Extensions for cross-platform compatibility
extension View {
	/// Cross-platform navigation bar title display mode
	@ViewBuilder
	func crossPlatformNavigationBarTitleDisplayMode(_ mode: CrossPlatformTitleDisplayMode) -> some View {
		#if os(macOS)
		self
		#else
		self.navigationBarTitleDisplayMode(mode.uiKitMode)
		#endif
	}

	/// Cross-platform autocapitalization
	@ViewBuilder
	func crossPlatformAutocapitalization(_ style: CrossPlatformAutocapitalization) -> some View {
		#if os(macOS)
		self
		#else
		self.textInputAutocapitalization(style.uiKitStyle)
		#endif
	}

	/// Cross-platform keyboard type
	@ViewBuilder
	func crossPlatformKeyboardType(_ type: CrossPlatformKeyboardType) -> some View {
		#if os(macOS)
		self
		#else
		self.keyboardType(type.uiKitType)
		#endif
	}
}

public enum CrossPlatformTitleDisplayMode {
	case inline
	case large
	case automatic

	#if !os(macOS)
	var uiKitMode: NavigationBarItem.TitleDisplayMode {
		switch self {
		case .inline: return .inline
		case .large: return .large
		case .automatic: return .automatic
		}
	}
	#endif
}

public enum CrossPlatformAutocapitalization {
	case none
	case words
	case sentences
	case allCharacters

	#if !os(macOS)
	var uiKitStyle: TextInputAutocapitalization {
		switch self {
		case .none: return .never
		case .words: return .words
		case .sentences: return .sentences
		case .allCharacters: return .characters
		}
	}
	#endif
}

public enum CrossPlatformKeyboardType {
	case `default`
	case numberPad
	case emailAddress
	case URL

	#if !os(macOS)
	var uiKitType: UIKeyboardType {
		switch self {
		case .default: return .default
		case .numberPad: return .numberPad
		case .emailAddress: return .emailAddress
		case .URL: return .URL
		}
	}
	#endif
}

// MARK: - Toolbar placement compatibility
extension ToolbarItemPlacement {
	#if os(macOS)
	static var crossPlatformLeading: ToolbarItemPlacement { .cancellationAction }
	static var crossPlatformTrailing: ToolbarItemPlacement { .confirmationAction }
	#else
	static var crossPlatformLeading: ToolbarItemPlacement { .navigationBarLeading }
	static var crossPlatformTrailing: ToolbarItemPlacement { .navigationBarTrailing }
	#endif
}

// MARK: - macOS Visual Effect Background
#if os(macOS)
struct VisualEffectBackground: NSViewRepresentable {
	let material: NSVisualEffectView.Material
	let blendingMode: NSVisualEffectView.BlendingMode

	init(material: NSVisualEffectView.Material = .sidebar, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
		self.material = material
		self.blendingMode = blendingMode
	}

	func makeNSView(context: Context) -> NSVisualEffectView {
		let view = NSVisualEffectView()
		view.material = material
		view.blendingMode = blendingMode
		view.state = .followsWindowActiveState
		return view
	}

	func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
		nsView.material = material
		nsView.blendingMode = blendingMode
	}
}

extension View {
	func visualEffectBackground(material: NSVisualEffectView.Material = .sidebar) -> some View {
		self.background(VisualEffectBackground(material: material))
	}
}
#endif

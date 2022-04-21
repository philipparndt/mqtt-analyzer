//
//  Logger.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-19.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

struct LogMessage: Identifiable, Hashable {
	let level: LogLevel
	let message: String
	let id = UUID()
}

enum LogLevel: Int {
	case none = 0
	case error = 1
	case warning = 2
	case info = 3
	case debug = 4
	case trace = 5
}

extension LogLevel: CustomStringConvertible {
	var description: String {
		switch self {
		case .none:
			return "NONE"
		case .error:
			return "ERROR"
		case .warning:
			return "WARN"
		case .info:
			return "INFO"
		case .debug:
			return "DEBUG"
		case .trace:
			return "TRACE"
		}
	}
}

class Logger: ObservableObject {
	var level: LogLevel
	@Published var messages: [LogMessage] = []
	
	init(level: LogLevel) {
		self.level = level
	}
	
	func log(level: LogLevel, _ message: String) {
		if level.rawValue <= self.level.rawValue {
			messages.append(LogMessage(level: level, message: message))
		}
	}
	
	func error(_ message: String) {
		log(level: .error, message)
	}

	func warning(_ message: String) {
		log(level: .warning, message)
	}

	func info(_ message: String) {
		log(level: .info, message)
	}
	
	func debug(_ message: String) {
		log(level: .debug, message)
	}
	
	func trace(_ message: String) {
		log(level: .trace, message)
	}
}

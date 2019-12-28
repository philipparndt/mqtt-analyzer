//
//  HostValidator.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-12-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import swift_petitparser

public class HostValidator {
    public class func validateHostname(name hostname: String) -> String? {
        let ip = NumbersParser
            .int(from: 1, to: 255)
            .seq(CharacterParser.of(".").seq(NumbersParser.int(from: 0, to: 255)))
            .seq(CharacterParser.of(".").seq(NumbersParser.int(from: 0, to: 255)))
            .seq(CharacterParser.of(".").seq(NumbersParser.int(from: 0, to: 255)))
        
        let host = CharacterParser.anyOf("a-zA-Z0-9.").plus()

        let parser = ip.or(host).trim().flatten().end()
        return parser.parse(hostname).get()
    }
}

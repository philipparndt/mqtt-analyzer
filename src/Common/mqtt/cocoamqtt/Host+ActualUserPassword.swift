//
//  Host+ActualUserPassword.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 19.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

extension Host {
	var actualUsername: String {
		usernameNonpersistent ?? username
	}

	var actualPassword: String {
		passwordNonpersistent ?? password
	}
}

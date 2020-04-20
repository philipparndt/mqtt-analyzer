//
//  MQTTCertificateFiles.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-03-01.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Moscapsule

func initCertificates(host: Host, config: MQTTConfig) -> (Bool, String?) {
	if let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
		let certFile = documents + "/\(host.certServerCA)"
		let usercertFile = documents + "/\(host.certClient)"
		let userkeyFile = documents + "/\(host.certClientKey)"
		let fm = FileManager.default
		
		for file in [certFile, usercertFile, userkeyFile] {
			if !fm.fileExists(atPath: file) {
				return (false, "\"\((file as NSString).lastPathComponent)\" not found")
			}
		}
		
		config.mqttServerCert = MQTTServerCert(cafile: certFile, capath: nil)
		config.mqttClientCert = MQTTClientCert(certfile: usercertFile,
											   keyfile: userkeyFile,
											   keyfile_passwd: host.certClientKeyPassword.isBlank ? nil : host.certClientKeyPassword)
		
		return (true, nil)
	}
	
	return (false, "document directory file not found")
}

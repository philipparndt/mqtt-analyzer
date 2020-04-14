//
//  HostFormModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

struct HostFormModel {
	var alias: String = ""
	var hostname: String = ""
	var port: String = "1883"
	var basePath: String = ""
	var topic: String = "#"
	
	var qos: Int = 0
	
	var username: String = ""
	var password: String = ""
	
	var certServerCA: String = ""
	var certClient: String = ""
	var certClientKey: String = ""
	var certClientKeyPassword: String = ""
	
	var clientID = ""
	
	var limitTopic = "250"
	var limitMessagesBatch = "1000"
}


func copyHost(target: Host, source host: HostFormModel, _ auth: HostAuthenticationType, _ connectionMethod: HostProtocol, _ clientImpl: HostClientImplType) -> Host? {
	let newHostname = HostFormValidator.validateHostname(name: host.hostname)
	let port = HostFormValidator.validatePort(port: host.port)
	
	if port == nil || newHostname == nil {
		return nil
	}
	
	target.alias = host.alias
	target.hostname = newHostname!
	target.qos = host.qos
	target.auth = auth
	target.port = UInt16(port!)
	target.topic = host.topic
	target.clientID = host.clientID
	target.auth = auth
	target.basePath = host.basePath
	target.protocolMethod = connectionMethod
	
	if target.protocolMethod == .websocket {
		target.clientImpl = .cocoamqtt
	}
	else {
		target.clientImpl = clientImpl
	}

	if auth == .usernamePassword {
		target.username = host.username
		target.password = host.password
	}
	else if auth == .certificate {
		target.certServerCA = host.certServerCA
		target.certClient = host.certClient
		target.certClientKey = host.certClientKey
		target.certClientKeyPassword = host.certClientKeyPassword
	}
	
	return target
}

func transformHost(source host: Host) -> HostFormModel {
	return HostFormModel(alias: host.alias,
						 hostname: host.hostname,
						 port: "\(host.port)",
						 basePath: host.basePath,
						 topic: host.topic,
						 qos: host.qos,
						 username: host.username,
						 password: host.password,
						 certServerCA: host.certServerCA,
						 certClient: host.certClient,
						 certClientKey: host.certClientKey,
						 certClientKeyPassword: host.certClientKeyPassword,
						 clientID: host.clientID,
						 limitTopic: "\(host.limitTopic)",
						 limitMessagesBatch: "\(host.limitMessagesBatch)")
}

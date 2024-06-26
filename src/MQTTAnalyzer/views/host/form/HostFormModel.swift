//
//  HostFormModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

class TopicSubscriptionFormModel: Identifiable, ObservableObject {
	var id = NSUUID().uuidString
	
	@Published var topic: String
	@Published var qos: Int
	
	init(topic: String, qos: Int) {
		self.topic = topic
		self.qos = qos
	}
}

enum RuntineError: Error {
	case runtimeError(String)
}

struct HostFormModel {
	var alias = ""
	var hostname = ""
	var port = "1883"
	var basePath = ""
	var subscriptions = [TopicSubscriptionFormModel(topic: "#", qos: 0)]
	
	var username = ""
	var password = ""
	
	var certServerCA: CertificateFile?
	var certClient: CertificateFile?
	var certClientKey: CertificateFile?
	var certP12: CertificateFile?
	var certClientKeyPassword = ""
	
	var clientID = ""
	
	var limitTopic = "1000"
	var limitMessagesBatch = "1000"
	
	var ssl = false
	var untrustedSSL = false
	
	var protocolMethod: HostProtocol = .mqtt
	var usernamePasswordAuth = false
	var certificateAuth = false
	var protocolVersion: HostProtocolVersion = .mqtt3
	
	var category = ""
}

func transform(subscriptions: [TopicSubscription]) -> [TopicSubscriptionFormModel] {
	return subscriptions.map { TopicSubscriptionFormModel(topic: $0.topic, qos: $0.qos)}
}

func transform(subscriptions: [TopicSubscriptionFormModel]) -> [TopicSubscription] {
	return subscriptions.map { TopicSubscription(topic: $0.topic, qos: $0.qos)}
}

func validate(source host: HostFormModel) -> Bool {
	let newHostname = HostFormValidator.validateHostname(name: host.hostname)
	let port = HostFormValidator.validatePort(port: host.port)
	
	if port == nil || newHostname == nil {
		return false
	}
	
	return true
}

func copyBroker(target: BrokerSetting, source host: HostFormModel) throws {
	let newHostname = HostFormValidator.validateHostname(name: host.hostname)
	let port = HostFormValidator.validatePort(port: host.port)
	
	if port == nil || newHostname == nil {
		throw RuntineError.runtimeError("Validation failed")
	}
	
	target.alias = host.alias
	target.hostname = newHostname!
	
	if host.usernamePasswordAuth && host.certificateAuth {
		target.authType = .both
	}
	else if host.usernamePasswordAuth {
		target.authType = .usernamePassword
	}
	else if host.certificateAuth {
		target.authType = .certificate
	}
	else {
		target.authType = .none
	}
	target.port = Int32(port!)
	target.subscriptions = Subscriptions(transform(subscriptions: host.subscriptions))
	target.clientID = host.clientID
	target.basePath = host.basePath
	target.protocolMethod = host.protocolMethod
	target.ssl = host.ssl
	target.untrustedSSL = host.ssl && host.untrustedSSL
	target.limitTopic = Int32(host.limitTopic) ?? 250
	target.limitMessagesBatch = Int32(host.limitMessagesBatch) ?? 1000
	target.protocolVersion = host.protocolVersion
	target.category = host.category
	
	if host.usernamePasswordAuth {
		target.username = host.username
		target.password = host.password
	}
	if host.certificateAuth {
		var certificates: [CertificateFile] = []
		
		if let cert = host.certServerCA {
			certificates.append(cert)
		}
		if let cert = host.certClient {
			certificates.append(cert)
		}
		if let cert = host.certClientKey {
			certificates.append(cert)
		}
		if let cert = host.certP12 {
			certificates.append(cert)
		}

		target.certificates = Certificates(certificates)
		target.certClientKeyPassword = host.certClientKeyPassword
	}
}

func transformHost(source host: Host) -> HostFormModel {
	return HostFormModel(
		alias: host.settings.alias,
		hostname: host.settings.hostname,
		port: "\(host.settings.port)",
		basePath: host.settings.basePath ?? "",
		subscriptions: transform(subscriptions: host.settings.subscriptions?.subscriptions ?? []),
		username: host.settings.username ?? "",
		password: host.settings.password ?? "",
		certServerCA: getCertificate(host, type: .serverCA),
	    certClient: getCertificate(host, type: .client),
		certClientKey: getCertificate(host, type: .clientKey),
		certP12: getCertificate(host, type: .p12),
		certClientKeyPassword: host.settings.certClientKeyPassword ?? "",
		clientID: host.settings.clientID ?? "",
		limitTopic: "\(host.settings.limitTopic)",
		limitMessagesBatch: "\(host.settings.limitMessagesBatch)",
		ssl: host.settings.ssl,
		untrustedSSL: host.settings.untrustedSSL,
		protocolMethod: host.settings.protocolMethod,
		usernamePasswordAuth: host.settings.authType == .usernamePassword || host.settings.authType == .both,
		certificateAuth: host.settings.authType == .certificate || host.settings.authType == .both,
		protocolVersion: host.settings.protocolVersion,
		category: host.settings.category ?? ""
	)
}

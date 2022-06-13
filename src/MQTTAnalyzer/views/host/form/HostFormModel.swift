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
	
	var limitTopic = "250"
	var limitMessagesBatch = "1000"
	
	var ssl = false
	var untrustedSSL = false
	
	var protocolMethod: HostProtocol = .mqtt
	var authType: HostAuthenticationType = .none
	var protocolVersion: HostProtocolVersion = .mqtt3
	
	var navigation: NavigationMode = .folders
	var maxMessagesOfSubFolders = "10"
}

func transform(subscriptions: [TopicSubscription]) -> [TopicSubscriptionFormModel] {
	return subscriptions.map { TopicSubscriptionFormModel(topic: $0.topic, qos: $0.qos)}
}

func transform(subscriptions: [TopicSubscriptionFormModel]) -> [TopicSubscription] {
	return subscriptions.map { TopicSubscription(topic: $0.topic, qos: $0.qos)}
}

func copyHost(target: Host, source host: HostFormModel) -> Host? {
	let newHostname = HostFormValidator.validateHostname(name: host.hostname)
	let port = HostFormValidator.validatePort(port: host.port)
	
	if port == nil || newHostname == nil {
		return nil
	}
	
	target.alias = host.alias
	target.hostname = newHostname!
	target.auth = host.authType
	target.port = UInt16(port!)
	target.subscriptions = transform(subscriptions: host.subscriptions)
	target.clientID = host.clientID
	target.basePath = host.basePath
	target.protocolMethod = host.protocolMethod
	target.ssl = host.ssl
	target.untrustedSSL = host.ssl && host.untrustedSSL
	target.limitTopic = Int(host.limitTopic) ?? 250
	target.limitMessagesBatch = Int(host.limitMessagesBatch) ?? 1000
	target.navigationMode = host.navigation
	target.maxMessagesOfSubFolders = Int(host.maxMessagesOfSubFolders) ?? 10
	target.protocolVersion = host.protocolVersion
	
	if host.authType == .usernamePassword {
		target.username = host.username
		target.password = host.password
	}
	else if host.authType == .certificate {
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

		target.certificates = certificates
		target.certClientKeyPassword = host.certClientKeyPassword
	}
	
	return target
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
	target.authType = Int32(PersistenceTransformer.transformAuth(host.authType))
	target.port = Int32(port!)
	target.subscriptions = PersistenceEncoder.encode(subscriptions:  transform(subscriptions: host.subscriptions))
	target.clientID = host.clientID
	target.basePath = host.basePath
	target.protocolMethod = Int32(PersistenceTransformer.transformConnectionMethod(host.protocolMethod))
	target.ssl = host.ssl
	target.untrustedSSL = host.ssl && host.untrustedSSL
	target.limitTopic = Int32(host.limitTopic) ?? 250
	target.limitMessagesBatch = Int32(host.limitMessagesBatch) ?? 1000
	target.protocolVersion = Int32(PersistenceTransformer.transformProtocolVersion(host.protocolVersion))
	
	if host.authType == .usernamePassword {
		target.username = host.username
		target.password = host.password
	}
	else if host.authType == .certificate {
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

		target.certificates = PersistenceEncoder.encode(certificates: certificates)
		target.certClientKeyPassword = host.certClientKeyPassword
	}
}

func transformHost(source host: Host) -> HostFormModel {
	return HostFormModel(alias: host.alias,
						 hostname: host.hostname,
						 port: "\(host.port)",
						 basePath: host.basePath,
						 subscriptions: transform(subscriptions: host.subscriptions),
						 username: host.username,
						 password: host.password,
						 certServerCA: getCertificate(host, type: .serverCA),
						 certClient: getCertificate(host, type: .client),
						 certClientKey: getCertificate(host, type: .clientKey),
						 certP12: getCertificate(host, type: .p12),
						 certClientKeyPassword: host.certClientKeyPassword,
						 clientID: host.clientID,
						 limitTopic: "\(host.limitTopic)",
						 limitMessagesBatch: "\(host.limitMessagesBatch)",
						 ssl: host.ssl,
						 untrustedSSL: host.untrustedSSL,
						 protocolMethod: host.protocolMethod,
						 authType: host.auth,
						 protocolVersion: host.protocolVersion,
						 navigation: host.navigationMode,
						 maxMessagesOfSubFolders: "\(host.maxMessagesOfSubFolders)"
						)
}

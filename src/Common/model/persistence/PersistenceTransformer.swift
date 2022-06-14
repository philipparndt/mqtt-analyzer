//
//  PersistenceTransformer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class PersistenceTransformer {
	class func transformAuth(_ type: HostAuthenticationType) -> Int8 {
		switch type {
		case .usernamePassword:
			return AuthenticationType.usernamePassword
		case .certificate:
			return AuthenticationType.certificate
		default:
			return AuthenticationType.none
		}
	}
	
	private class func transformAuth(_ type: Int8) -> HostAuthenticationType {
		switch type {
		case AuthenticationType.usernamePassword:
			return HostAuthenticationType.usernamePassword
		case AuthenticationType.certificate:
			return HostAuthenticationType.certificate
		default:
			return HostAuthenticationType.none
		}
	}
	
	class func transformConnectionMethod(_ type: HostProtocol) -> Int8 {
		switch type {
		case .websocket:
			return ConnectionMethod.websocket
		default:
			return ConnectionMethod.mqtt
		}
	}
	
	private class func transformConnectionMethod(_ type: Int8) -> HostProtocol {
		switch type {
		case ConnectionMethod.mqtt:
			return .mqtt
		case ConnectionMethod.websocket:
			return .websocket
		default:
			return .mqtt
		}
	}
	
	class func transformNavigationMode(_ type: NavigationMode) -> Int8 {
		switch type {
		case .folders:
			return NavigationModeType.folders
		default:
			return NavigationModeType.classic
		}
	}
	
	private class func transformNavigationMode(_ type: Int8) -> NavigationMode {
		switch type {
		case NavigationModeType.folders:
			return .folders
		case NavigationModeType.classic:
			return .classic
		default:
			return .folders
		}
	}
	
	class func transformProtocolVersion(_ type: HostProtocolVersion) -> Int8 {
		switch type {
		case .mqtt5:
			return HostProtocolVersionType.mqtt5
		default:
			return HostProtocolVersionType.mqtt3
		}
	}
	
	private class func transformProtocolVersion(_ type: Int8) -> HostProtocolVersion {
		switch type {
		case HostProtocolVersionType.mqtt5:
			return .mqtt5
		case HostProtocolVersionType.mqtt3:
			return .mqtt3
		default:
			return .mqtt3
		}
	}
		
	class func transformToSQLite(from host: Host) -> SQLiteBrokerSetting {
		return SQLiteBrokerSetting(
			id: host.ID,
			alias: host.alias,
			hostname: host.hostname,
			port: Int(host.port),
			subscriptions: SubscriptionValueTransformer.encode(subscriptions: host.subscriptions),
			protocolMethod: Int(transformConnectionMethod(host.protocolMethod)),
			basePath: host.basePath,
			ssl: host.ssl,
			untrustedSSL: host.untrustedSSL,
			protocolVersion: Int(transformProtocolVersion(host.protocolVersion)),
			authType: Int(transformAuth(host.auth)),
			username: host.username,
			password: host.password,
			certificates: CertificateValueTransformer.encode(certificates: host.certificates),
			certClientKeyPassword: host.certClientKeyPassword,
			clientID: host.clientID,
			limitTopic: host.limitTopic,
			limitMessagesBatch: host.limitMessagesBatch,
			deleted: host.deleted
		)
	}
	
	class func transform(from host: SQLiteBrokerSetting) -> Host {
		let result = Host(id: host.id)
		result.deleted = host.deleted
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = UInt16(host.port)
		result.subscriptions = SubscriptionValueTransformer.decode(subscriptions: host.subscriptions)
		result.auth = transformAuth(Int8(host.authType))
		result.username = host.username
		result.password = host.password
		result.certificates = CertificateValueTransformer.decode(certificates: host.certificates)
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		result.protocolMethod = transformConnectionMethod(Int8(host.protocolMethod))
		result.protocolVersion = transformProtocolVersion(Int8(host.protocolVersion))
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		return result
	}
	
	class func transform(from host: BrokerSetting) -> Host {
		let result = Host(id: host.id?.uuidString ?? "")
		result.deleted = host.isDeleted
		result.alias = host.alias ?? ""
		result.hostname = host.hostname ?? ""
		result.port = UInt16(host.port)
		result.subscriptions = host.subscriptions?.subscriptions ?? []
		result.auth = host.authType
		result.username = host.username ?? ""
		result.password = host.password ?? ""
		result.certificates = host.certificates?.files ?? []
		result.certClientKeyPassword = host.certClientKeyPassword ?? ""
		result.clientID = host.clientID ?? ""
		result.limitTopic = Int(host.limitTopic)
		result.limitMessagesBatch = Int(host.limitMessagesBatch)
		result.protocolMethod = host.protocolMethod
		result.protocolVersion = host.protocolVersion
		result.basePath = host.basePath ?? ""
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		return result
	}
}

//
//  PersistenceTransformer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

class PersistenceTransformer {
	private class func transformAuth(_ type: HostAuthenticationType) -> Int8 {
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
	
	private class func transformConnectionMethod(_ type: HostProtocol) -> Int8 {
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
	
	private class func transformNavigationMode(_ type: NavigationMode) -> Int8 {
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
	
	private class func transformProtocolVersion(_ type: HostProtocolVersion) -> Int8 {
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
	
	class func transform(from host: HostSetting) -> Host {
		let result = Host(id: host.id)
		result.deleted = host.isDeleted
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = UInt16(host.port)
		result.subscriptions = PersistenceEncoder.decode(subscriptions: host.subscriptions)
		result.auth = transformAuth(host.authType)
		result.username = host.username
		result.password = host.password
		result.certificates = PersistenceEncoder.decode(certificates: host.certificates)
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		result.protocolMethod = transformConnectionMethod(host.protocolMethod)
		result.protocolVersion = transformProtocolVersion(host.protocolVersion)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		result.navigationMode = transformNavigationMode(host.navigationMode)
		result.maxMessagesOfSubFolders = host.maxMessagesOfSubFolders
		return result
	}
		
	class func transformToRealm(from host: Host) -> HostSetting {
		let result = HostSetting()
		copy(from: host, to: result)
		return result
	}
	
	class func copy(from host: Host, to result: HostSetting) {
		result.isDeleted = host.deleted
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = Int32(host.port)
		result.subscriptions = PersistenceEncoder.encode(subscriptions: host.subscriptions)
		result.authType = transformAuth(host.auth)
		result.username = host.username
		result.password = host.password
		result.certificates = PersistenceEncoder.encode(certificates: host.certificates)
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		result.protocolMethod = transformConnectionMethod(host.protocolMethod)
		result.protocolVersion = transformProtocolVersion(host.protocolVersion)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		result.navigationMode = transformNavigationMode(host.navigationMode)
		result.maxMessagesOfSubFolders = host.maxMessagesOfSubFolders
	}
	
	class func transformToSQLite(from host: Host) -> SQLiteBrokerSetting {
		return SQLiteBrokerSetting(
			id: host.ID,
			alias: host.alias,
			hostname: host.hostname,
			port: Int(host.port),
			subscriptions: PersistenceEncoder.encode(subscriptions: host.subscriptions),
			protocolMethod: Int(transformConnectionMethod(host.protocolMethod)),
			basePath: host.basePath,
			ssl: host.ssl,
			untrustedSSL: host.untrustedSSL,
			protocolVersion: Int(transformProtocolVersion(host.protocolVersion)),
			authType: Int(transformAuth(host.auth)),
			username: host.username,
			password: host.password,
			certificates: PersistenceEncoder.encode(certificates: host.certificates),
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
		result.subscriptions = PersistenceEncoder.decode(subscriptions: host.subscriptions)
		result.auth = transformAuth(Int8(host.authType))
		result.username = host.username
		result.password = host.password
		result.certificates = PersistenceEncoder.decode(certificates: host.certificates)
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
}

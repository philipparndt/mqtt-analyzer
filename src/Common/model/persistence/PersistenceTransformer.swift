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
	
	class func transformAuth(_ type: Int8) -> HostAuthenticationType {
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
	
	class func transformConnectionMethod(_ type: Int8) -> HostProtocol {
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
	
	class func transformProtocolVersion(_ type: Int8) -> HostProtocolVersion {
		switch type {
		case HostProtocolVersionType.mqtt5:
			return .mqtt5
		case HostProtocolVersionType.mqtt3:
			return .mqtt3
		default:
			return .mqtt3
		}
	}
		
	class func transformToSQLite(from settings: BrokerSetting) -> SQLiteBrokerSetting {
		return SQLiteBrokerSetting(
			id: settings.id?.uuidString ?? "",
			alias: settings.alias,
			hostname: settings.hostname,
			port: Int(settings.port),
			subscriptions: SubscriptionValueTransformer.encode(subscriptions: settings.subscriptions?.subscriptions ?? []),
			protocolMethod: Int(transformConnectionMethod(settings.protocolMethod)),
			basePath: settings.basePath ?? "",
			ssl: settings.ssl,
			untrustedSSL: settings.untrustedSSL,
			protocolVersion: Int(transformProtocolVersion(settings.protocolVersion)),
			authType: Int(transformAuth(settings.authType)),
			username: settings.username ?? "",
			password: settings.password ?? "",
			certificates: CertificateValueTransformer.encode(certificates: settings.certificates?.files ?? []),
			certClientKeyPassword: settings.certClientKeyPassword ?? "",
			clientID: settings.clientID ?? "",
			limitTopic: Int(settings.limitTopic),
			limitMessagesBatch: Int(settings.limitMessagesBatch),
			deleted: settings.isDeleted,
			category: settings.category ?? ""
		)
	}
}

//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// swiftlint:disable force_try
public class HostsModelPersistence {
	let model: HostsModel
	let realm: Realm
	var token: NotificationToken?
	
	init(model: HostsModel) {
		self.model = model
		self.realm = HostsModelPersistence.initRelam()
	}
	
	class func initRelam() -> Realm {
		return try! Realm()
	}
	
	func create(_ host: Host) {
		let setting = transform(host)
		
		do {
			try realm.write {
				realm.add(setting)
			}
		}
		catch {
			NSLog("Error creating entry in database: \(error.localizedDescription)")
		}
	}
		
	func update(_ host: Host) {
		let settings = realm.objects(HostSetting.self)
			.filter("id = %@", host.ID)
		
		if let setting = settings.first {
			do {
				try realm.write {
					setting.alias = host.alias
					setting.hostname = host.hostname
					setting.port = Int32(host.port)
					setting.subscriptions = HostsModelPersistence.encode(subscriptions: host.subscriptions)
					setting.authType = transformAuth(host.auth)
					setting.username = host.username
					setting.password = host.password
					setting.certificates = HostsModelPersistence.encode(certificates: host.certificates)
					setting.certClientKeyPassword = host.certClientKeyPassword
					setting.clientID = host.clientID
					setting.limitTopic = host.limitTopic
					setting.limitMessagesBatch = host.limitMessagesBatch
					setting.protocolMethod = transformConnectionMethod(host.protocolMethod)
					setting.clientImplType = transformClientImplType(host.clientImpl)
					setting.basePath = host.basePath
					setting.ssl = host.ssl
					setting.untrustedSSL = host.untrustedSSL
				}
			}
			catch {
				NSLog("Error updating database: \(error.localizedDescription)")
			}
			
		}
	}
	
	func delete(_ host: Host) {
		let settings = realm.objects(HostSetting.self)
			.filter("id = %@", host.ID)
		
		if let setting = settings.first {
			do {
				try realm.write {
					setting.isDeleted = true
				}
			}
			catch {
				NSLog("Error deleting entry from database: \(error.localizedDescription)")
			}
		}
	}
	
	func load() {
		HostSettingExamples.inititalize(realm: realm)
		
		let settings = realm.objects(HostSetting.self)
		
		token?.invalidate()
		
		token = settings.observe { (_: RealmCollectionChange) in
			self.pushModel(settings: settings)
		}
	}
	
	private func pushModel(settings: Results<HostSetting>) {
		let hosts: [Host] = settings
		.filter { !$0.isDeleted }
		.map { self.transform($0) }
		
		DispatchQueue.main.async {
			self.model.hosts = hosts
		}
	}
	
	private func transformAuth(_ type: HostAuthenticationType) -> Int8 {
		switch type {
		case .usernamePassword:
			return AuthenticationType.usernamePassword
		case .certificate:
			return AuthenticationType.certificate
		default:
			return AuthenticationType.none
		}
	}
	
	private func transformAuth(_ type: Int8) -> HostAuthenticationType {
		switch type {
		case AuthenticationType.usernamePassword:
			return HostAuthenticationType.usernamePassword
		case AuthenticationType.certificate:
			return HostAuthenticationType.certificate
		default:
			return HostAuthenticationType.none
		}
	}
	
	private func transformConnectionMethod(_ type: HostProtocol) -> Int8 {
		switch type {
		case .websocket:
			return ConnectionMethod.websocket
		default:
			return ConnectionMethod.mqtt
		}
	}
	
	private func transformConnectionMethod(_ type: Int8) -> HostProtocol {
		switch type {
		case ConnectionMethod.mqtt:
			return .mqtt
		case ConnectionMethod.websocket:
			return .websocket
		default:
			return .mqtt
		}
	}
	
	private func transformClientImplType(_ type: HostClientImplType) -> Int8 {
		switch type {
		case .cocoamqtt:
			return ClientImplType.cocoamqtt
		default:
			return ClientImplType.moscapsule
		}
	}
	
	private func transformClientImplType(_ type: Int8) -> HostClientImplType {
		switch type {
		case ClientImplType.cocoamqtt:
			return .cocoamqtt
		default:
			return .moscapsule
		}
	}
	
	class func encode(subscriptions: [TopicSubscription]) -> Data {
		do {
			return try JSONEncoder().encode(subscriptions)
		} catch {
			NSLog("Unexpected error encoding subscriptions: \(error).")
			return Data()
		}
	}
	
	class func decode(subscriptions: Data) -> [TopicSubscription] {
		do {
			if subscriptions.isEmpty {
				return []
			}
			
			return try JSONDecoder().decode([TopicSubscription].self, from: subscriptions)
		} catch {
			NSLog("Unexpected error decoding subscriptions: \(error).")
			NSLog("`\(String(data: subscriptions, encoding: .utf8)!)`")
			return [TopicSubscription(topic: "#", qos: 0)]
		}
	}
	
	class func encode(certificates: [CertificateFile]) -> Data {
		do {
			return try JSONEncoder().encode(certificates)
		} catch {
			NSLog("Unexpected error encoding certificate files: \(error).")
			return Data()
		}
	}
	
	class func decode(certificates: Data) -> [CertificateFile] {
		do {
			if certificates.isEmpty {
				return []
			}
			
			return try JSONDecoder().decode([CertificateFile].self, from: certificates)
		} catch {
			NSLog("Unexpected error decoding certificate files: \(error).")
			return []
		}
	}
	
	func transform(_ host: HostSetting) -> Host {
		let result = Host(id: host.id)
		result.deleted = host.isDeleted
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = UInt16(host.port)
		result.subscriptions = HostsModelPersistence.decode(subscriptions: host.subscriptions)
		result.auth = transformAuth(host.authType)
		result.username = host.username
		result.password = host.password
		result.certificates = HostsModelPersistence.decode(certificates: host.certificates)
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		result.protocolMethod = transformConnectionMethod(host.protocolMethod)
		result.clientImpl = transformClientImplType(host.clientImplType)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		return result
	}
	
	func transform(_ host: Host) -> HostSetting {
		let result = HostSetting()
		result.isDeleted = host.deleted
		result.id = host.ID
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = Int32(host.port)
		result.subscriptions = HostsModelPersistence.encode(subscriptions: host.subscriptions)
		result.authType = transformAuth(host.auth)
		result.username = host.username
		result.password = host.password
		result.certificates = HostsModelPersistence.encode(certificates: host.certificates)
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		result.protocolMethod = transformConnectionMethod(host.protocolMethod)
		result.clientImplType = transformClientImplType(host.clientImpl)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		return result
	}
}

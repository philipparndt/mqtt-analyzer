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
public class RealmPersistence: Persistence {
	let model: HostsModel
	let realm: Realm
	var token: NotificationToken?
	
	init(model: HostsModel) {
		self.model = model
		self.realm = RealmPersistence.initRelam()
	}
	
	class func initRelam() -> Realm {
		return try! Realm()
	}
	
	func create(_ host: Host) {
		if CommandLine.arguments.contains("--ui-testing") {
			return
		}

		let setting = RealmPresistenceTransformer.transform(host)
		
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
					RealmPresistenceTransformer.copy(from: host, to: setting)
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
		.map { RealmPresistenceTransformer.transform($0) }
		
		DispatchQueue.main.async {
			self.model.hosts = hosts
		}
	}
	
}

class RealmPresistenceTransformer {
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
	
	private class func transformClientImplType(_ type: HostClientImplType) -> Int8 {
		return ClientImplType.cocoamqtt
	}
	
	private class func transformClientImplType(_ type: Int8) -> HostClientImplType {
		return .cocoamqtt
	}
	
	class func transform(_ host: HostSetting) -> Host {
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
		result.clientImpl = transformClientImplType(host.clientImplType)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		result.navigationMode = transformNavigationMode(host.navigationMode)
		result.maxMessagesOfSubFolders = host.maxMessagesOfSubFolders
		return result
	}
		
	class func transform(_ host: Host) -> HostSetting {
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
		result.clientImplType = transformClientImplType(host.clientImpl)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		result.navigationMode = transformNavigationMode(host.navigationMode)
		result.maxMessagesOfSubFolders = host.maxMessagesOfSubFolders
	}
}

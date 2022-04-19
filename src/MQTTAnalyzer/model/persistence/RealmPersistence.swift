//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

public class RealmPersistence: Persistence {
	let model: HostsModel
	let realm: Realm
	var token: NotificationToken?
	
	init?(model: HostsModel) {
		self.model = model
		
		if let realm = RealmPersistence.initRealm() {
			self.realm = realm
		}
		else {
			return nil
		}
	}
	
	class func initRealm() -> Realm? {
		do {
			return try Realm()
		}
		catch {
			NSLog("Unable to initialize persistence, using stub persistence. \(error)")
			return nil
		}
		
	}
	
	func create(_ host: Host) {
		if CommandLine.arguments.contains("--ui-testing") {
			return
		}

		let setting = RealmPersistenceTransformer.transform(host)
		
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
					RealmPersistenceTransformer.copy(from: host, to: setting)
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
		
		load()
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
		.map { RealmPersistenceTransformer.transform($0) }
		
		DispatchQueue.main.async {
			self.model.hosts = hosts
		}
	}
	
}

class RealmPersistenceTransformer {
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
		result.protocolVersion = transformProtocolVersion(host.protocolVersion)
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
		result.protocolVersion = transformProtocolVersion(host.protocolVersion)
		result.basePath = host.basePath
		result.ssl = host.ssl
		result.untrustedSSL = host.untrustedSSL
		result.navigationMode = transformNavigationMode(host.navigationMode)
		result.maxMessagesOfSubFolders = host.maxMessagesOfSubFolders
	}
}

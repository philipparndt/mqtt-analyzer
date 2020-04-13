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
					setting.topic = host.topic
					setting.qos = host.qos
					setting.authType = transformAuth(host.auth)
					setting.username = host.username
					setting.password = host.password
					setting.certServerCA = host.certServerCA
					setting.certClient = host.certClient
					setting.certClientKey = host.certClientKey
					setting.certClientKeyPassword = host.certClientKeyPassword
					setting.clientID = host.clientID
					setting.limitTopic = host.limitTopic
					setting.limitMessagesBatch = host.limitMessagesBatch
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
			return AuthenticationType.USERNAME_PASSWORD
		case .certificate:
			return AuthenticationType.CERTIFICATE
		default:
			return AuthenticationType.NONE
		}
	}
	
	private func transformAuth(_ type: Int8) -> HostAuthenticationType {
		switch type {
		case AuthenticationType.USERNAME_PASSWORD:
			return HostAuthenticationType.usernamePassword
		case AuthenticationType.CERTIFICATE:
			return HostAuthenticationType.certificate
		default:
			return HostAuthenticationType.none
		}
	}
	
	func transform(_ host: HostSetting) -> Host {
		let result = Host(id: host.id)
		result.deleted = host.isDeleted
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = UInt16(host.port)
		result.topic = host.topic
		result.qos = host.qos
		result.auth = transformAuth(host.authType)
		result.username = host.username
		result.password = host.password
		result.certServerCA = host.certServerCA
		result.certClient = host.certClient
		result.certClientKey = host.certClientKey
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		return result
	}
	
	func transform(_ host: Host) -> HostSetting {
		let result = HostSetting()
		result.isDeleted = host.deleted
		result.id = host.ID
		result.alias = host.alias
		result.hostname = host.hostname
		result.port = Int32(host.port)
		result.topic = host.topic
		result.qos = host.qos
		result.authType = transformAuth(host.auth)
		result.username = host.username
		result.password = host.password
		result.certServerCA = host.certServerCA
		result.certClient = host.certClient
		result.certClientKey = host.certClientKey
		result.certClientKeyPassword = host.certClientKeyPassword
		result.clientID = host.clientID
		result.limitTopic = host.limitTopic
		result.limitMessagesBatch = host.limitMessagesBatch
		return result
	}
}

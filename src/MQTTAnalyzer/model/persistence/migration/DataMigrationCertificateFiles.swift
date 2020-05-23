//
//  MultipleTopics.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-10.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

// Added support for multiple topics
class DataMigrationCertificateFiles {

	class func migrate(_ oldSchemaVersion: UInt64, _ migration: Migration) {
		if oldSchemaVersion < 21 {
			migration.enumerateObjects(ofType: HostSetting.className()) { oldObject, newObject in
				if let oo = oldObject, let no = newObject {
					_ = migrateCertificates(oldObject, oo, no)
				}
			}
		}
	}

	private class func migrateCertificates(_ oldObject: MigrationObject?, _ oo: MigrationObject, _ no: MigrationObject) -> Bool {
		if hasProperties(oldObject, properties: "certServerCA", "certClient", "certClientKey") {
			let clientImplType = getClientImplType(oldObject, oo)
			
			if clientImplType == ClientImplType.moscapsule {
				var files: [CertificateFile] = []
				
				if let name = oo.value(forKey: "certServerCA") as? String {
					files.append(CertificateFile(name: name, location: .local, type: .serverCA))
				}
				if let name = oo.value(forKey: "certClient") as? String {
					files.append(CertificateFile(name: name, location: .local, type: .client))
				}
				if let name = oo.value(forKey: "certClientKey") as? String {
					files.append(CertificateFile(name: name, location: .local, type: .clientKey))
				}
				
				no["certificates"] = HostsModelPersistence.encode(certificates: files)
				return true
			}
			else {
				if let name = oo.value(forKey: "certClient") as? String {
					if !name.isEmpty {
						no["certificates"] = HostsModelPersistence.encode(certificates: [
							CertificateFile(name: name, location: .local, type: .p12)
						])
					}
					return true
				}
			}
		}
		
		return false
	}
	
	private class func getClientImplType(_ oldObject: MigrationObject?, _ oo: MigrationObject) -> Int8 {
		if hasProperties(oldObject, properties: "clientImplType") {
			if let type = oo.value(forKey: "clientImplType") as? Int8 {
				return type
			}
		}
		return ClientImplType.moscapsule
	}
	
}

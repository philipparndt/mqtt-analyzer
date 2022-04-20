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
			if let name = oo.value(forKey: "certClient") as? String {
				if !name.isEmpty {
					no["certificates"] = PersistenceEncoder.encode(certificates: [
						CertificateFile(name: name, location: .local, type: .p12)
					])
				}
				return true
			}
		}
		
		return false
	}
	
}

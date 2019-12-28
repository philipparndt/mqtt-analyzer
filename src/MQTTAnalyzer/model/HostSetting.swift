//
//  HostSetting.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-21.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

import RealmSwift
import IceCream
import CloudKit

class HostSetting: Object {
    @objc dynamic var id = NSUUID().uuidString
    @objc dynamic var alias = ""
    @objc dynamic var hostname = ""
    @objc dynamic var port: Int32 = 1883
    @objc dynamic var topic: String = "#"
    @objc dynamic var qos: Int = 0

    @objc dynamic var auth: Bool = false
    @objc dynamic var username: String = ""
    @objc dynamic var password: String = ""

    @objc dynamic var isDeleted = false
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension HostSetting: CKRecordConvertible {
}

extension HostSetting: CKRecordRecoverable {
}

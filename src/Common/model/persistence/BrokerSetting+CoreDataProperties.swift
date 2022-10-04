//
//  BrokerSetting+CoreDataProperties.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 14.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//
//

import Foundation
import CoreData

extension BrokerSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BrokerSetting> {
        return NSFetchRequest<BrokerSetting>(entityName: "BrokerSetting")
    }

    @NSManaged public var alias: String
    @NSManaged public var authType: HostAuthenticationType
    @NSManaged public var basePath: String?
    @NSManaged public var certClientKeyPassword: String?
    @NSManaged public var certificates: Certificates?
    @NSManaged public var clientID: String?
    @NSManaged public var hostname: String
    @NSManaged public var id: UUID?
    @NSManaged public var limitMessagesBatch: Int32
    @NSManaged public var limitTopic: Int32
    @NSManaged public var password: String?
    @NSManaged public var port: Int32
    @NSManaged public var protocolMethod: HostProtocol
    @NSManaged public var protocolVersion: HostProtocolVersion
    @NSManaged public var ssl: Bool
    @NSManaged public var subscriptions: Subscriptions?
    @NSManaged public var untrustedSSL: Bool
    @NSManaged public var username: String?

}

extension BrokerSetting: Identifiable {

}

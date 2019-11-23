//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift

class HostsModelPersistence {
    let model : HostsModel
    let realm : Realm
    var token : NotificationToken? = nil
    
    init(model: HostsModel) {
        self.model = model
        self.realm = try! Realm()
    }
    
    func create(_ host: Host) {
        let setting = transform(host)

        let realm = try! Realm()
        try! realm.write {
            realm.add(setting)
        }
    }
        
    func update(_ host: Host) {
        let settings = realm.objects(HostSetting.self)
            .filter("id = %@", host.ID)
        
        if let setting = settings.first {
            try! realm.write {
                setting.alias = host.alias
                setting.hostname = host.hostname
                setting.topic = host.topic
                setting.qos = host.qos
                setting.auth = host.auth
                setting.username = host.username
                setting.password = host.password
            }
        }
    }
    
    func delete(_ host: Host) {
        let settings = realm.objects(HostSetting.self)
            .filter("id = %@", host.id)
        
        if let setting = settings.first {
            try! realm.write {
                setting.isDeleted = true
            }
        }
    }
    
    func load() {
        HostSettingExamples.inititalize(realm: realm)
        
        let settings = realm.objects(HostSetting.self)
        
        token?.invalidate()
        
        token = settings.observe {
            (changes: RealmCollectionChange) in
            self.pushModel(settings: settings)
        }
    }
    
    private func pushModel(settings: Results<HostSetting>) {
        self.model.hosts = []
        
        let hosts : [Host] = settings
        .filter { !$0.isDeleted }
        .map { self.transform($0) }
        self.model.hosts = hosts
    }
    
    private func transform(_ host: HostSetting) -> Host {
        let result = Host()
        result.deleted = host.isDeleted
        result.ID = host.id
        result.alias = host.alias
        result.hostname = host.hostname
        result.topic = host.topic
        result.qos = host.qos
        result.auth = host.auth
        result.username = host.username
        result.password = host.password
        return result
    }
    
    private func transform(_ host: Host) -> HostSetting {
        let result = HostSetting()
        result.isDeleted = host.deleted
        result.id = host.ID
        result.alias = host.alias
        result.hostname = host.hostname
        result.topic = host.topic
        result.qos = host.qos
        result.auth = host.auth
        result.username = host.username
        result.password = host.password
        return result
    }
}

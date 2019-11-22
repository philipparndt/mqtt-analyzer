//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation
import RealmSwift
import RxRealm
import RxSwift

class HostsModelPersistence {
    let bag = DisposeBag()
    let model : HostsModel
    
    init(model: HostsModel) {
        self.model = model
    }
    
    func create(_ host: Host) {
        let setting = transform(host)

        let realm = try! Realm()
        try! realm.write {
            realm.add(setting)
        }
    }
        
    func update(_ host: Host) {
        let realm = try! Realm()
        let settings = realm.objects(HostSetting.self)
            .filter("id = %@", host.id)
        
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
        let realm = try! Realm()
        let settings = realm.objects(HostSetting.self)
            .filter("id = %@", host.id)
        
        if let setting = settings.first {
            try! realm.write {
                setting.isDeleted = true
            }
        }
    }
    
    private func initializeExampleData(realm: Realm) {
        let example1 = HostSetting()
        example1.id = "example.test.mosquitto.org.1"
        example1.alias = "Water levels"
        example1.auth = false
        example1.hostname = "test.mosquitto.org"
        example1.username = ""
        example1.password = ""
        example1.port = 1883
        example1.qos = 0
        example1.topic = "de.wsv/#"
        
        let example2 = HostSetting()
        example2.id = "example.test.mosquitto.org.2"
        example2.alias = "Revspace sensors"
        example2.auth = false
        example2.hostname = "test.mosquitto.org"
        example2.username = ""
        example2.password = ""
        example2.port = 1883
        example2.qos = 0
        example2.topic = "revspace/sensors/#"
        
        createIfNotPresent(setting: example1, realm: realm)
        createIfNotPresent(setting: example2, realm: realm)
    }
    
    private func createIfNotPresent(setting: HostSetting, realm: Realm) {
        let settings = realm.objects(HostSetting.self)
             .filter("id = %@", setting.id)
        
        if (settings.isEmpty) {
            try! realm.write {
                realm.add(setting)
            }
        }
    }
    
    func load() {
        let realm = try! Realm()
        
        initializeExampleData(realm: realm)
        
        let settings = realm.objects(HostSetting.self)
        
        Observable.array(from: settings).subscribe(onNext: { (settings) in
            self.model.hosts = settings
                .filter { !$0.isDeleted }
                .map { self.transform($0) }
        }).disposed(by: self.bag)
    }
    
    private func transform(_ host: HostSetting) -> Host {
        let result = Host()
        result.deleted = host.isDeleted
        result.id = host.id
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
        result.id = host.id
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

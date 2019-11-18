//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

private struct HostPersistable : Codable {
    var alias : String = ""
    var hostname : String = ""
    var port : Int32 = 1883
    var topic : String = "#"
    
    var qos : Int = 0
    
    var auth : Bool = false
    var username : String = ""
    var password : String = ""
}

class HostsModelPersistence {
    class func persist(_ hosts: [Host]) {
        let hostsPersist = hosts.map { transform($0) }
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(hostsPersist)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)

            let store = NSUbiquitousKeyValueStore.default
            store.set(json, forKey: "hosts")
            store.synchronize()
            
//            let userDefaults = UserDefaults.standard
//            let clientIDPersistenceKey = "hosts"
//
//            userDefaults.set(json, forKey: clientIDPersistenceKey)
            
            NSLog(json!)
            
        } catch {
            // TODO: Implement error dialog
            let nserror = error as NSError
            fatalError("Unable to persist the hosts error \(nserror), \(nserror.userInfo)")
        }
    }
    
    class func load() -> HostsModel {
        let json = loadJson()
        let jsonDecoder = JSONDecoder()
         do {
            let hosts = try jsonDecoder.decode([HostPersistable].self, from: json.data(using: .utf8)!)
            
            return HostsModel(hosts: hosts.map { transform($0) })
            
        } catch {
            // TODO: Implement error dialog
            let nserror = error as NSError
            fatalError("Unable to persist the hosts error \(nserror), \(nserror.userInfo)")
        }
    }
    
    class func loadJson() -> String {
//        let userDefaults = UserDefaults.standard
//        let clientIDPersistenceKey = "hosts"
        
        let store = NSUbiquitousKeyValueStore.default
        if (!store.bool(forKey: "hosts-initialized.1")) {
            store.set("""
                [
                    {
                        "alias": "Water levels",
                        "auth": false,
                        "hostname": "test.mosquitto.org",
                        "password": "",
                        "port": 1883,
                        "qos": 0,
                        "topic": "de.wsv/#",
                        "username": ""
                    },
                    {
                        "alias": "Revspace sensors",
                        "auth": false,
                        "hostname": "test.mosquitto.org",
                        "password": "",
                        "port": 1883,
                        "qos": 0,
                        "topic": "revspace/sensors/#",
                        "username": ""
                    }
                ]
            """, forKey: "hosts")
            
            store.set(true, forKey: "hosts-initialized.1")
            store.synchronize()
        }
        
        return store.string(forKey: "hosts") ?? "[]"
    }
    
    private class func transform(_ host: HostPersistable) -> Host {
        let result = Host()
        result.alias = host.alias
        result.hostname = host.hostname
        result.topic = host.topic
        result.qos = host.qos
        result.auth = host.auth
        result.username = host.username
        result.password = host.password
        return result
    }
    
    private class func transform(_ host: Host) -> HostPersistable {
        return HostPersistable(alias: host.alias,
            hostname: host.hostname,
            port: host.port,
            topic: host.topic,
            qos: host.qos,
            auth: host.auth,
            username: host.username,
            password: host.password)
    }
}

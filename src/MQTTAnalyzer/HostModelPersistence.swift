//
//  HostModelPersistence.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-15.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import Foundation

struct HostPersistable : Codable {
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
        let hostsPersist = hosts.map {
            HostPersistable(alias: $0.alias,
                            hostname: $0.hostname, port: $0.port, topic: $0.topic, qos: $0.qos, auth: $0.auth, username: $0.username, password: $0.password)
        }
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(hostsPersist)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)

            let userDefaults = UserDefaults.standard
            let clientIDPersistenceKey = "hosts"

            userDefaults.set(json, forKey: clientIDPersistenceKey)
            
            NSLog(json!)
            
        } catch {
            // TODO: Implement error dialog
            let nserror = error as NSError
            fatalError("Unable to persist the hosts error \(nserror), \(nserror.userInfo)")
        }
    }
    
    class func load() -> HostsModel {
        let userDefaults = UserDefaults.standard
        let clientIDPersistenceKey = "hosts"
        
        if let json = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
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
        
        let host = Host()
        //        host.alias = "pisvr"
        //        host.hostname = "192.168.3.3"
        host.alias = "Mosquitto Test server"
        host.hostname = "test.mosquitto.org"
        host.topic = "de.wsv/#"
        //host.topic = "revspace/sensors/co2/#"
        //host.topic = "revspace/#"
        return HostsModel(hosts: [host])
    }
    
    class func transform(_ persistable: HostPersistable) -> Host {
        let host = Host()
        host.alias = persistable.alias
        host.hostname = persistable.hostname
        host.topic = persistable.topic
        host.qos = persistable.qos
        host.auth = persistable.auth
        host.username = persistable.username
        host.password = persistable.password
        return host
    }
}

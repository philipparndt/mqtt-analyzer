//
//  PersistenceStub.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2022-02-06.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

public class StubPersistence: Persistence {
	let model: HostsModel
	var hosts: [Host] = []
	
	init(model: HostsModel) {
		self.model = model
		
		initExamples()
	}
	
	func delete(_ host: Host) {
		hosts = hosts.filter { $0.ID != host.ID }
		load()
	}
	
	func initExamples() {
		hosts = [
			StubPersistence.toHost(HostSettingExamples.example1()),
			StubPersistence.toHost(HostSettingExamples.example2()),
			StubPersistence.toHost(HostSettingExamples.exampleRnd7()),
			StubPersistence.toHost(HostSettingExamples.exampleLocalhost())
		]
	}
	
	class func toHost(_ host: SQLiteBrokerSetting) -> Host {
		let setting = BrokerSetting()
		PersistenceHelper.create(
			host: host,
			setting: setting
		)
		
		return Host(settings: setting)
	}
	
	func load() {
		model.hosts = hosts
	}
	
	func create(_ host: Host) {
		hosts.append(host)
	}
		
	func update(_ host: Host) {
		// Not supported for the stub model
	}

}

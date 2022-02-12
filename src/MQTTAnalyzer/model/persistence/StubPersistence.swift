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
	}
	
	func initExamples() {
		hosts = [
			HostSettingExamples.example1(),
			HostSettingExamples.example2(),
			HostSettingExamples.exampleLocalhost()
		]
	}
	
	func load() {
		model.hosts = hosts
	}
	
	func create(_ host: Host) {
		hosts.append(host)
	}
		
	func update(_ host: Host) {
	}

}

//
//  CertificateFilesModel.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-29.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

protocol CertificateFilesRefresh {
	func refresh()
}

struct LogMessage: Identifiable, Hashable {
	let message: String
	let id = UUID()
}

class CertificateFilesModel: ObservableObject, CertificateFilesRefresh {
    static let instance = CertificateFilesModel()
	
	@Published var cloudFiles: [CertificateFileModel] = []
	@Published var localFiles: [CertificateFileModel] = []
	
	@Published var log: [LogMessage] = []
	
	init() {
		refresh()
	}
	
	func delete(at offsets: IndexSet, on location: CertificateLocation) -> [CertificateFileModel] {
		var result: [CertificateFileModel] = []
		if location == .local {
			offsets.forEach {
				let toBeDeleted = localFiles[$0]
				result.append(toBeDeleted)
				CloudDataManager.instance.deleteLocalFile(fileName: toBeDeleted.name)
				
				localFiles.remove(at: $0)
			}
		}

		return result
	}
	
	func getFiles(of location: CertificateLocation) -> [CertificateFileModel] {
		if location == .cloud {
			return cloudFiles
		}
		else {
			return localFiles
		}
	}
	
	func log(message: String) {
		log.append(LogMessage(message: message))
	}
	
	func refresh() {
		FileLister.logger = log
		CloudDataManager.logger = log
		
		log.append(LogMessage(message: "DEBUG: Refreshing files"))
		localFiles = FileLister.listFiles(on: .local)
		
		if CloudDataManager.instance.isCloudEnabled() {
			cloudFiles = FileLister.listFiles(on: .cloud)
		}
		else {
			log.append(LogMessage(message: "WARN: Cloud disabled"))
		}
	}
}

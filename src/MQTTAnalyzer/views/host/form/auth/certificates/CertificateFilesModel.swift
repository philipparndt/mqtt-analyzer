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

class CertificateFilesModel: ObservableObject, CertificateFilesRefresh {
    static let instance = CertificateFilesModel()
	
	@Published var cloudFiles: [CertificateFileModel] = []
	@Published var localFiles: [CertificateFileModel] = []
	
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
	
	func refresh() {
		localFiles = FileLister.listFiles(on: .local)
		
		if CloudDataManager.instance.isCloudEnabled() {
			cloudFiles = FileLister.listFiles(on: .cloud)
		}
	}
}

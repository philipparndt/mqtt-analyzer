//
//  FileLister.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

class FileLister: ObservableObject {
	@Published var files: [CertificateFileModel]
	
	init(location: CertificateLocation) {
		self.files = FileLister.listFiles(on: location)
	}
	
	func refresh(on certificateLocation: CertificateLocation) {
		files = FileLister.listFiles(on: certificateLocation)
	}
	
	class func getDefaultLocation() -> CertificateLocation {
		return .local
	}
	
	class func getUrl(on location: CertificateLocation) -> URL {
		if location == .cloud {
			if let url = CloudDataManager.sharedInstance.getCloudDocumentDiretoryURL() {
				return url
			}
		}

		return CloudDataManager.sharedInstance.getLocalDocumentDiretoryURL()
	}
	
	class func listFiles(on location: CertificateLocation) -> [CertificateFileModel] {
		do {
			let url = FileLister.getUrl(on: location)
			
			CloudDataManager.sharedInstance.initDocumentsDirectory()
			
			let directoryContents = try FileManager.default
				.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
			
			let files = directoryContents
				.map { $0.lastPathComponent }
				.filter { $0.lowercased().range(of: #".*\.(p12|pfx|crt|key)$"#, options: .regularExpression) != nil}
				.map { CertificateFileModel(name: $0, location: location) }
				.sorted()

			return files
		} catch {
			return [CertificateFileModel(name: error.localizedDescription, location: location)]
		}
	}
}

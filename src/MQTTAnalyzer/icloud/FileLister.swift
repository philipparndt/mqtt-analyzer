//
//  FileLister.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-22.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine

class FileLister {
	class func getUrl(on location: CertificateLocation) -> URL {
		if location == .cloud {
			if let url = CloudDataManager.instance.getCloudDocumentDiretoryURL() {
				return url
			}
		}

		return CloudDataManager.instance.getLocalDocumentDiretoryURL()
	}
	
	class func listFiles(on location: CertificateLocation) -> [CertificateFileModel] {
		do {
			let url = FileLister.getUrl(on: location)
			
			CloudDataManager.instance.initDocumentsDirectory()
			
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

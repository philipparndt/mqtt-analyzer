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
	
	class func downloadUbiquitousItems(folder url: URL, contents: [URL]) throws {
		try contents
			.filter { $0.lastPathComponent.lowercased()
				.range(of: #"^\..*\.p12.icloud$"#, options: .regularExpression) != nil }
			.forEach {
				if FileManager.default.isUbiquitousItem(at: $0) {
					NSLog("Downloading ubiquitous item \($0)")
					try FileManager.default.startDownloadingUbiquitousItem(at: $0)
				}
			}
	}
	
	class func listFiles(on location: CertificateLocation) -> [CertificateFileModel] {
		do {
			let url = FileLister.getUrl(on: location)
			
			CloudDataManager.instance.initDocumentsDirectory()
			
			let directoryContents = try FileManager.default
				.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
			
			try downloadUbiquitousItems(folder: url, contents: directoryContents)
						
			let files = directoryContents
				.map { $0.lastPathComponent }
				.filter { $0.lowercased().range(of: #".*\.p12$"#, options: .regularExpression) != nil}
				.map { CertificateFileModel(name: $0, location: location) }
				.sorted()

			return files
		} catch {
			return [CertificateFileModel(name: error.localizedDescription, location: location)]
		}
	}
}

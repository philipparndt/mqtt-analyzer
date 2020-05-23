//
//  CloudDataManager.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-17.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//
// with parts from:
// https://stackoverflow.com/questions/33886846/best-way-to-use-icloud-documents-storage

import Foundation

class CloudDataManager {

    static let sharedInstance = CloudDataManager() // Singleton

    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default
			.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask)
			.last!
		
        static let iCloudDocumentsURL = FileManager.default
			.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

	func initDocumentsDirectory() {
		if !isCloudEnabled() {
			return
		}
		
		if let url = DocumentsDirectory.iCloudDocumentsURL {
			if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
				do {
					try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					print(error.localizedDescription)
				}
			}
			
			do {
				try FileManager.default.startDownloadingUbiquitousItem(at: url)
			}
			catch {
				print(error.localizedDescription)
			}
		}
	}

    // Return true if iCloud is enabled
    func isCloudEnabled() -> Bool {
        return DocumentsDirectory.iCloudDocumentsURL != nil
    }
	
	func getCloudDocumentDiretoryURL() -> URL? {
		return DocumentsDirectory.iCloudDocumentsURL
    }

	func getLocalDocumentDiretoryURL() -> URL {
		return DocumentsDirectory.localDocumentsURL
    }
}

extension CertificateFile {
	func getBaseUrl(certificate: CertificateFile) throws -> URL {
		if certificate.location == .cloud {
			if let url = CloudDataManager.sharedInstance.getCloudDocumentDiretoryURL() {
				return url
			}
			else {
				throw CertificateError.noClound
			}
		}
		else {
			return CloudDataManager.sharedInstance.getLocalDocumentDiretoryURL()
		}
	}
}

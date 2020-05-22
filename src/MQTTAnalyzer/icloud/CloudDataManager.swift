//
//  CloudDataManager.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-17.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
class CloudDataManager {

    static let sharedInstance = CloudDataManager() // Singleton

    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
        static let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
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
	
    // Return the Document directory (Cloud OR Local)
    // To do in a background thread
    func getDocumentDiretoryURL() -> URL {
        if isCloudEnabled() {
            return DocumentsDirectory.iCloudDocumentsURL!
        } else {
            return DocumentsDirectory.localDocumentsURL
        }
    }

    // Return true if iCloud is enabled
    func isCloudEnabled() -> Bool {
        if DocumentsDirectory.iCloudDocumentsURL != nil { return true }
        else { return false }
    }
	
	func getiCloudDocumentDiretoryURL() -> URL? {
		return DocumentsDirectory.iCloudDocumentsURL
    }

	func getLocalDocumentDiretoryURL() -> URL {
		return DocumentsDirectory.localDocumentsURL
    }
}

extension CertificateFile {
	func getBaseUrl(certificate: CertificateFile) throws -> URL {
		if certificate.location == .cloud {
			if let url = CloudDataManager.sharedInstance.getiCloudDocumentDiretoryURL() {
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

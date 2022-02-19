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
	class func noop(message: String) {}
	
	static var logger: (String) -> Void = noop

    static let instance = CloudDataManager()

    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default
			.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask)
			.last!
		
        static let iCloudDocumentsURL = FileManager.default
			.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

	func initDocumentsDirectory() {
		if !isCloudEnabled() {
			CloudDataManager.logger("WARN initDocumentsDirectory - Cloud disabled")
			return
		}
		
		if let url = DocumentsDirectory.iCloudDocumentsURL {
			if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
				CloudDataManager.logger("INFO initDocumentsDirectory")
				do {
					try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					CloudDataManager.logger("ERROR initDocumentsDirectory: \(error.localizedDescription)")
					print(error.localizedDescription)
				}
				
				initDescriptionFile(url: url)
			}
		}
	}

	func initDescriptionFile(url: URL) {
		do {
			let fileURL = url.appendingPathComponent("README.txt")
			let text = "# PKCS#12 Certificates\n"
			+ "Place your .p12 or .pfx files here.\n\n"
			+ "# OpenSSL\n"
			+ "Use openssl to create this files:\n"
			+ "`pkcs12 -export -in user.crt -inkey user.key -out user.p12`"
			try text.write(to: fileURL, atomically: false, encoding: .utf8)
			
			try FileManager.default.startDownloadingUbiquitousItem(at: url)
		}
		catch {
			print(error.localizedDescription)
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
	
	func copyFileToLocal(file: URL) {
		let fileManager = FileManager.default
		do {
			let target = DocumentsDirectory.localDocumentsURL.appendingPathComponent(file.lastPathComponent)
			
			if fileManager.fileExists(atPath: target.path) {
				try fileManager.removeItem(at: target)
			}
			
			try fileManager.copyItem(at: file,
									 to: DocumentsDirectory.localDocumentsURL.appendingPathComponent(file.lastPathComponent))
			CloudDataManager.logger("DEBUG Copied \(file) to local dir")
		} catch let error as NSError {
			CloudDataManager.logger("ERROR Failed to copy file to local directory: \(error)")
		}
	}
	
	func deleteLocalFile(fileName: String) {
		let fileManager = FileManager.default
		do {
			try fileManager.removeItem(at: DocumentsDirectory.localDocumentsURL.appendingPathComponent(fileName))
			CloudDataManager.logger("DEBUG Deleted file \(fileName)")
		} catch let error as NSError {
			CloudDataManager.logger("ERROR Failed to delete file: \(error)")
		}
	}
}

extension CertificateFile {
	func getBaseUrl(certificate: CertificateFile) throws -> URL {
		if certificate.location == .cloud {
			if let url = CloudDataManager.instance.getCloudDocumentDiretoryURL() {
				return url
			}
			else {
				throw CertificateError.noClound
			}
		}
		else {
			return CloudDataManager.instance.getLocalDocumentDiretoryURL()
		}
	}
}

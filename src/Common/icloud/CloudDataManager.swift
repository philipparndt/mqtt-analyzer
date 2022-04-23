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
	static var logger = Logger(level: .none)

    static let instance = CloudDataManager()

    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default
			.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask)
			.last
		
        static let iCloudDocumentsURL = FileManager.default
			.url(forUbiquityContainerIdentifier: nil)?
			.appendingPathComponent("Documents")
    }

	func initDocumentsDirectory() {
		if !isCloudEnabled() {
			CloudDataManager.logger.info("Cloud disabled")
			return
		}
		
		if let url = DocumentsDirectory.iCloudDocumentsURL {
			if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
				CloudDataManager.logger.trace("initDocumentsDirectory")
				do {
					try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					CloudDataManager.logger.error("initDocumentsDirectory: \(error.localizedDescription)")
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
			CloudDataManager.logger.error(error.localizedDescription)
		}
	}
	
    // Return true if iCloud is enabled
    func isCloudEnabled() -> Bool {
        return DocumentsDirectory.iCloudDocumentsURL != nil
    }
	
	func getCloudDocumentDiretoryURL() -> URL? {
		return DocumentsDirectory.iCloudDocumentsURL
    }

	func getLocalDocumentDiretoryURL() -> URL? {
		return DocumentsDirectory.localDocumentsURL
    }
	
	func copyFileToLocal(file: URL) {
		let fileManager = FileManager.default
		do {
			if let url = DocumentsDirectory.localDocumentsURL {
				let target = url.appendingPathComponent(file.lastPathComponent)
				
				if fileManager.fileExists(atPath: target.path) {
					try fileManager.removeItem(at: target)
				}
				
				try fileManager.copyItem(at: file,
										 to: url.appendingPathComponent(file.lastPathComponent))
				CloudDataManager.logger.debug("Copied \(file) to local dir")
			}
			else {
				CloudDataManager.logger.error("Local URL not found")
			}
		} catch let error as NSError {
			CloudDataManager.logger.error("Failed to copy file to local directory: \(error)")
		}
	}
	
	func deleteLocalFile(fileName: String) {
		let fileManager = FileManager.default
		do {
			if let url = DocumentsDirectory.localDocumentsURL {
				try fileManager.removeItem(at: url.appendingPathComponent(fileName))
				CloudDataManager.logger.debug("Deleted file \(fileName)")
			}
			else {
				CloudDataManager.logger.error("Local URL not found")
			}
			
		} catch let error as NSError {
			CloudDataManager.logger.error("Failed to delete file: \(error)")
		}
	}
}

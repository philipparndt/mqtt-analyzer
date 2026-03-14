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

	/// Copies a file to the iCloud Documents directory
	/// - Parameters:
	///   - file: The source file URL to copy
	///   - sourceHash: Optional hash of the source file (computed if not provided)
	/// - Returns: The resulting filename if successful, nil otherwise
	func copyFileToCloud(file: URL, sourceHash: String? = nil) -> String? {
		let fileManager = FileManager.default
		do {
			guard let url = DocumentsDirectory.iCloudDocumentsURL else {
				CloudDataManager.logger.error("iCloud URL not found")
				return nil
			}

			// Ensure the iCloud Documents directory exists
			if !fileManager.fileExists(atPath: url.path) {
				try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
			}

			let originalName = file.lastPathComponent
			var target = url.appendingPathComponent(originalName)

			// Check if source and target are the same file (already in iCloud)
			if file.standardizedFileURL == target.standardizedFileURL {
				CloudDataManager.logger.debug("File \(originalName) is already in iCloud")
				return originalName
			}

			// Also check if the file is inside the iCloud container (different path representation)
			if file.path.contains("/Mobile Documents/") && file.lastPathComponent == target.lastPathComponent {
				// Check if it's the same file by comparing resolved paths
				let sourcePath = file.resolvingSymlinksInPath().path
				let targetPath = target.resolvingSymlinksInPath().path
				if sourcePath == targetPath {
					CloudDataManager.logger.debug("File \(originalName) is already in iCloud (resolved)")
					return originalName
				}
			}

			// If a file with the same name exists, check if it's the same content
			if fileManager.fileExists(atPath: target.path) {
				let hash = sourceHash ?? computeFileHash(url: file)
				let existingHash = computeFileHash(url: target)

				if hash != nil && hash == existingHash {
					// Same content, no need to copy
					CloudDataManager.logger.debug("File \(originalName) already exists in iCloud with same content")
					return originalName
				}

				// Different content - generate a unique filename
				let uniqueName = generateUniqueFilename(originalName: originalName, inDirectory: url)
				target = url.appendingPathComponent(uniqueName)
				CloudDataManager.logger.debug("File conflict: renaming to \(uniqueName)")
			}

			try fileManager.copyItem(at: file, to: target)
			CloudDataManager.logger.debug("Copied \(file) to iCloud dir as \(target.lastPathComponent)")
			return target.lastPathComponent
		} catch let error as NSError {
			CloudDataManager.logger.error("Failed to copy file to iCloud directory: \(error)")
			return nil
		}
	}

	/// Generates a unique filename by appending a number suffix
	private func generateUniqueFilename(originalName: String, inDirectory directory: URL) -> String {
		let fileManager = FileManager.default
		let nameWithoutExtension = (originalName as NSString).deletingPathExtension
		let fileExtension = (originalName as NSString).pathExtension

		var counter = 1
		var newName = originalName

		while fileManager.fileExists(atPath: directory.appendingPathComponent(newName).path) {
			if fileExtension.isEmpty {
				newName = "\(nameWithoutExtension)-\(counter)"
			} else {
				newName = "\(nameWithoutExtension)-\(counter).\(fileExtension)"
			}
			counter += 1
		}

		return newName
	}
}

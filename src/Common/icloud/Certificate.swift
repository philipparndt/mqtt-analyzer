//
//  Certificate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation
import CryptoKit

func getCertificate(_ host: Host, type: CertificateFileType) -> CertificateFile? {
	return host.certificates.filter { $0.type == type }.first
}

/// Computes SHA256 hash of file contents
func computeFileHash(url: URL) -> String? {
	guard let data = try? Data(contentsOf: url) else {
		return nil
	}
	let hash = SHA256.hash(data: data)
	return hash.compactMap { String(format: "%02x", $0) }.joined()
}

extension CertificateFile {
	func getBaseUrl(certificate: CertificateFile) throws -> URL {
		if certificate.location == .cloud {
			if let url = CloudDataManager.instance.getCloudDocumentDiretoryURL() {
				return url
			}
			else {
				CloudDataManager.logger.error("No cloud URL found (Cloud disbled?)")
				throw CertificateError.noCloud
			}
		}
		else {
			if let url = CloudDataManager.instance.getLocalDocumentDiretoryURL() {
				return url
			}
			else {
				CloudDataManager.logger.error("No local URL found")
				throw CertificateError.noLocalURL
			}
		}
	}

	/// Returns the full path to the certificate file
	func getFullPath() throws -> URL {
		var baseUrl = try getBaseUrl(certificate: self)
		baseUrl.appendPathComponent(name)
		return baseUrl
	}

	/// Checks if the certificate file exists on this device and matches the stored hash
	func exists() -> Bool {
		do {
			let url = try getFullPath()
			guard FileManager.default.fileExists(atPath: url.path) else {
				return false
			}

			// If we have a stored hash, verify it matches
			if let storedHash = fileHash {
				guard let currentHash = computeFileHash(url: url) else {
					return false
				}
				return storedHash == currentHash
			}

			// No hash stored (legacy certificate), assume file exists
			return true
		} catch {
			return false
		}
	}

	/// Checks if a file exists but has a different hash (wrong certificate)
	func existsButDifferent() -> Bool {
		guard let storedHash = fileHash else {
			return false  // No hash to compare
		}

		do {
			let url = try getFullPath()
			guard FileManager.default.fileExists(atPath: url.path) else {
				return false  // File doesn't exist
			}

			guard let currentHash = computeFileHash(url: url) else {
				return false
			}

			return storedHash != currentHash
		} catch {
			return false
		}
	}
}

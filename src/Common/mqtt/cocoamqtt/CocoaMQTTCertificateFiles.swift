//
//  CertificateFiles.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT
import Security

// MARK: - Certificate Validation

/// Result of certificate validation
struct CertificateValidationResult {
	let isValid: Bool
	let message: String
	let details: String?

	static func valid(_ message: String, details: String? = nil) -> CertificateValidationResult {
		CertificateValidationResult(isValid: true, message: message, details: details)
	}

	static func invalid(_ message: String, details: String? = nil) -> CertificateValidationResult {
		CertificateValidationResult(isValid: false, message: message, details: details)
	}
}

/// Validates a certificate file based on its type
/// - Parameters:
///   - url: URL to the certificate file
///   - type: The expected certificate type
///   - password: Password for P12 files (optional)
/// - Returns: Validation result with success/failure and descriptive message
func validateCertificateFile(url: URL, type: CertificateFileType, password: String = "") -> CertificateValidationResult {
	guard let data = try? Data(contentsOf: url) else {
		return .invalid("Cannot read file")
	}

	switch type {
	case .p12:
		return validateClientP12(data: data, password: password)
	case .serverCA:
		return validateServerCA(url: url, data: data, password: password)
	case .client, .clientKey:
		return validatePEMFile(data: data, type: type)
	case .undefined:
		return .valid("File selected")
	}
}

/// Creates import options for SecPKCS12Import
/// On macOS 15+, uses kSecImportToMemoryOnly to prevent keychain storage during validation
private func createP12ImportOptions(password: String) -> NSDictionary {
	var optionsDict: [String: Any] = [kSecImportExportPassphrase as String: password]

	// On macOS 15+, use kSecImportToMemoryOnly to prevent keychain storage
	// This avoids the "wants to access key" keychain prompt during validation
	#if os(macOS)
	if #available(macOS 15.0, *) {
		optionsDict[kSecImportToMemoryOnly as String] = kCFBooleanTrue as Any
	}
	#endif

	return optionsDict as NSDictionary
}

/// Validates a Client P12 file (must contain identity: certificate + private key)
private func validateClientP12(data: Data, password: String) -> CertificateValidationResult {
	let options = createP12ImportOptions(password: password)
	var items: CFArray?
	let status = SecPKCS12Import(data as CFData, options, &items)

	switch status {
	case errSecSuccess:
		guard let array = items as? [[String: Any]], !array.isEmpty else {
			return .invalid("P12 file is empty")
		}

		// Check for identity (certificate + private key)
		for item in array where item[kSecImportItemIdentity as String] != nil {
			// Extract certificate info for display
			if let certChain = item[kSecImportItemCertChain as String] as? [SecCertificate],
			   let cert = certChain.first {
				let subject = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"
				return .valid("Certificate and password verified", details: "Subject: \(subject)")
			}
			return .valid("Certificate and password verified")
		}
		let details = "This file contains certificates but no private key. " +
			"For mTLS client authentication, use a P12 file that includes both certificate and private key."
		return .invalid("No client identity found", details: details)

	case errSecAuthFailed:
		return .invalid("Wrong password", details: "The password does not match the P12 file.")

	case errSecDecode:
		return .invalid("Invalid P12 format", details: "The file could not be decoded as PKCS#12.")

	default:
		return .invalid("Cannot open P12 file", details: "Error code: \(status)")
	}
}

/// Validates a Server CA file (PEM, CRT, DER, or P12 containing only certificates)
private func validateServerCA(url: URL, data: Data, password: String) -> CertificateValidationResult {
	let ext = url.pathExtension.lowercased()

	if ext == "p12" || ext == "pfx" {
		return validateServerCAP12(data: data, password: password)
	} else {
		return validateServerCAPEM(data: data)
	}
}

/// Validates a Server CA P12 file (contains certificates, no identity needed)
private func validateServerCAP12(data: Data, password: String) -> CertificateValidationResult {
	// Try with provided password first, then with common defaults
	let passwords = password.isEmpty ? ["password", ""] : [password]

	for pwd in passwords {
		let options = createP12ImportOptions(password: pwd)
		var items: CFArray?
		let status = SecPKCS12Import(data as CFData, options, &items)

		if status == errSecSuccess {
			guard let array = items as? [[String: Any]], !array.isEmpty else {
				return .invalid("P12 file is empty")
			}

			var certCount = 0
			var subjects: [String] = []

			for item in array {
				if let certChain = item[kSecImportItemCertChain as String] as? [SecCertificate] {
					certCount += certChain.count
					for cert in certChain {
						if let subject = SecCertificateCopySubjectSummary(cert) as String? {
							subjects.append(subject)
						}
					}
				}
			}

			if certCount > 0 {
				let details = subjects.isEmpty ? nil : "Certificates: \(subjects.joined(separator: ", "))"
				return .valid("Valid CA bundle (\(certCount) certificate\(certCount == 1 ? "" : "s"))", details: details)
			}

			return .invalid("No certificates found in P12")
		} else if status == errSecAuthFailed && pwd == password && !password.isEmpty {
			return .invalid("Wrong password")
		}
	}

	return .invalid("Cannot open P12 file", details: "Try password: 'password' (common default)")
}

/// Validates a Server CA PEM/CRT/DER file
private func validateServerCAPEM(data: Data) -> CertificateValidationResult {
	// Try as DER format first
	if let cert = SecCertificateCreateWithData(nil, data as CFData) {
		let subject = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"
		return .valid("Valid CA certificate", details: "Subject: \(subject)")
	}

	// Try as PEM format
	guard let pemString = String(data: data, encoding: .utf8) else {
		return .invalid("Invalid certificate format", details: "File is neither DER nor PEM encoded")
	}

	let certPattern = "-----BEGIN CERTIFICATE-----([\\s\\S]*?)-----END CERTIFICATE-----"
	guard let regex = try? NSRegularExpression(pattern: certPattern, options: []) else {
		return .invalid("Internal error parsing PEM")
	}

	let matches = regex.matches(in: pemString, options: [], range: NSRange(pemString.startIndex..., in: pemString))

	if matches.isEmpty {
		// Check if it looks like a private key
		if pemString.contains("-----BEGIN") && pemString.contains("PRIVATE KEY-----") {
			return .invalid("This is a private key, not a CA certificate", details: "Server CA should be a certificate file (.crt, .pem, or .p12)")
		}
		return .invalid("No certificates found", details: "File does not contain PEM-encoded certificates")
	}

	var validCerts = 0
	var subjects: [String] = []

	for match in matches {
		if let range = Range(match.range(at: 1), in: pemString) {
			let base64String = pemString[range]
				.replacingOccurrences(of: "\n", with: "")
				.replacingOccurrences(of: "\r", with: "")
				.trimmingCharacters(in: .whitespaces)

			if let certData = Data(base64Encoded: base64String),
			   let cert = SecCertificateCreateWithData(nil, certData as CFData) {
				validCerts += 1
				if let subject = SecCertificateCopySubjectSummary(cert) as String? {
					subjects.append(subject)
				}
			}
		}
	}

	if validCerts > 0 {
		let details = subjects.isEmpty ? nil : "Certificates: \(subjects.joined(separator: ", "))"
		return .valid("Valid CA certificate\(validCerts == 1 ? "" : "s") (\(validCerts))", details: details)
	}

	return .invalid("Certificates could not be parsed")
}

/// Validates a PEM file (client certificate or key)
private func validatePEMFile(data: Data, type: CertificateFileType) -> CertificateValidationResult {
	guard let pemString = String(data: data, encoding: .utf8) else {
		return .invalid("Cannot read file as text")
	}

	if type == .clientKey {
		if pemString.contains("-----BEGIN") && pemString.contains("PRIVATE KEY-----") {
			return .valid("Valid private key")
		}
		return .invalid("Not a private key file")
	}

	// Client certificate
	if pemString.contains("-----BEGIN CERTIFICATE-----") {
		return .valid("Valid certificate")
	}

	return .invalid("Not a certificate file")
}

// MARK: - SSL Settings

// Create P12 File by using:
// openssl pkcs12 -export -in user.crt -inkey user.key -out user.p12
func createSSLSettings(host: Host) throws -> [String: NSObject] {
	if let certificate = getCertificate(host, type: .p12) {
		let clientCertArray = try getClientCertFromP12File(certificate: certificate, certPassword: host.settings.certClientKeyPassword ?? "")

		var sslSettings: [String: NSObject] = [:]
		sslSettings[kCFStreamSSLCertificates as String] = clientCertArray

		return sslSettings
	}
	throw CertificateError.clientCertificateFileUndefined
}

/// Loads Server CA certificates for validating the server's certificate
/// - Parameter host: The host configuration containing certificate settings
/// - Returns: Array of SecCertificate objects, or nil if no Server CA is configured
func loadServerCACertificates(host: Host) throws -> [SecCertificate]? {
	guard let serverCA = getCertificate(host, type: .serverCA) else {
		NSLog("loadServerCACertificates: No server CA certificate configured")
		return nil
	}

	NSLog("loadServerCACertificates: Loading server CA: \(serverCA.name)")
	var url = try serverCA.getBaseUrl(certificate: serverCA)
	url.appendPathComponent(serverCA.name)

	NSLog("loadServerCACertificates: Full path: \(url.path)")

	let fileExtension = (serverCA.name as NSString).pathExtension.lowercased()
	NSLog("loadServerCACertificates: File extension: \(fileExtension)")

	if fileExtension == "p12" || fileExtension == "pfx" {
		NSLog("loadServerCACertificates: Loading as P12")
		// Try the provided password first, then common defaults
		let providedPassword = host.settings.certClientKeyPassword ?? ""
		let passwordsToTry = providedPassword.isEmpty
			? ["password", ""]
			: [providedPassword, "password", ""]

		for password in passwordsToTry {
			if let certs = try? loadCertificatesFromP12(url: url, password: password), !certs.isEmpty {
				NSLog("loadServerCACertificates: Loaded \(certs.count) certs from P12")
				return certs
			}
		}
		// If all passwords fail, throw with the original password
		return try loadCertificatesFromP12(url: url, password: providedPassword)
	} else {
		// Assume PEM/CRT/DER format
		NSLog("loadServerCACertificates: Loading as PEM/CRT/DER")
		let certs = try loadCertificatesFromPEM(url: url)
		NSLog("loadServerCACertificates: Loaded \(certs.count) certificates total")
		return certs
	}
}

/// Load certificates from a P12 file (extracts CA certificates, not identity)
private func loadCertificatesFromP12(url: URL, password: String) throws -> [SecCertificate] {
	guard let p12Data = NSData(contentsOf: url) else {
		throw CertificateError.serverCAOpenError
	}

	let options = createP12ImportOptions(password: password)
	var items: CFArray?
	let securityError = SecPKCS12Import(p12Data, options, &items)

	guard securityError == errSecSuccess else {
		if securityError == errSecAuthFailed {
			throw CertificateError.serverCAPasswordError
		} else {
			throw CertificateError.serverCAOpenError
		}
	}

	guard let theArray = items as? [[String: Any]], !theArray.isEmpty else {
		throw CertificateError.serverCANoCertificate
	}

	var certificates: [SecCertificate] = []

	for item in theArray {
		// Try to get the certificate chain
		if let certChain = item[kSecImportItemCertChain as String] as? [SecCertificate] {
			certificates.append(contentsOf: certChain)
		}

		// Also try to get the trust and extract certificates from it
		if let trust = item[kSecImportItemTrust as String] {
			let secTrust = trust as! SecTrust
			if let certChainFromTrust = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate] {
				for cert in certChainFromTrust
					where !certificates.contains(where: { SecCertificateCopyData($0) == SecCertificateCopyData(cert) }) {
					certificates.append(cert)
				}
			}
		}
	}

	if certificates.isEmpty {
		throw CertificateError.serverCANoCertificate
	}

	return certificates
}

/// Load certificates from PEM/CRT/DER file
private func loadCertificatesFromPEM(url: URL) throws -> [SecCertificate] {
	NSLog("loadCertificatesFromPEM: Loading from \(url.path)")
	guard let data = try? Data(contentsOf: url) else {
		NSLog("loadCertificatesFromPEM: Failed to read file")
		throw CertificateError.serverCAOpenError
	}

	NSLog("loadCertificatesFromPEM: File read successfully, size=\(data.count) bytes")
	var certificates: [SecCertificate] = []

	// Try as DER format first
	if let cert = SecCertificateCreateWithData(nil, data as CFData) {
		NSLog("loadCertificatesFromPEM: Successfully loaded as DER format")
		certificates.append(cert)
		return certificates
	}

	NSLog("loadCertificatesFromPEM: DER format failed, trying PEM")

	// Try as PEM format
	guard let pemString = String(data: data, encoding: .utf8) else {
		NSLog("loadCertificatesFromPEM: Failed to decode as UTF-8 string")
		throw CertificateError.serverCAInvalidFormat
	}

	// Extract all certificates from PEM
	let certPattern = "-----BEGIN CERTIFICATE-----([\\s\\S]*?)-----END CERTIFICATE-----"
	guard let regex = try? NSRegularExpression(pattern: certPattern, options: []) else {
		NSLog("loadCertificatesFromPEM: Failed to create regex pattern")
		throw CertificateError.serverCAInvalidFormat
	}

	let matches = regex.matches(in: pemString, options: [], range: NSRange(pemString.startIndex..., in: pemString))
	NSLog("loadCertificatesFromPEM: Found \(matches.count) PEM certificate blocks")

	for (index, match) in matches.enumerated() {
		if let range = Range(match.range(at: 1), in: pemString) {
			let base64String = pemString[range]
				.replacingOccurrences(of: "\n", with: "")
				.replacingOccurrences(of: "\r", with: "")
				.trimmingCharacters(in: .whitespaces)

			NSLog("loadCertificatesFromPEM: Processing certificate \(index + 1), base64 length=\(base64String.count)")

			if let certData = Data(base64Encoded: base64String) {
				NSLog("loadCertificatesFromPEM: Decoded base64, DER size=\(certData.count) bytes")
				if let cert = SecCertificateCreateWithData(nil, certData as CFData) {
					NSLog("loadCertificatesFromPEM: Successfully created SecCertificate for cert \(index + 1)")
					certificates.append(cert)
				} else {
					NSLog("loadCertificatesFromPEM: Failed to create SecCertificate for cert \(index + 1)")
				}
			} else {
				NSLog("loadCertificatesFromPEM: Failed to decode base64 for cert \(index + 1)")
			}
		}
	}

	NSLog("loadCertificatesFromPEM: Total certificates loaded: \(certificates.count)")

	if certificates.isEmpty {
		NSLog("loadCertificatesFromPEM: No certificates were successfully loaded")
		throw CertificateError.serverCANoCertificate
	}

	return certificates
}

enum CertificateError: String, Error {
	case errorOpenFile = "Failed to open the certificate file"
	case errSecAuthFailed = "Failed to open the certificate file. Wrong password?"
	case noIdentify = "Client P12 has no identity (certificate + private key). For Server CA validation, use the Server CA field instead."
	case clientCertificateFileUndefined = "Client certificate file is undefined. Review the settings."
	case noCloud = "iCloud is disabled but certificate was persisted in iCloud."
	case noLocalURL = "Local URL not found. MQTTAnalyzer folder does not exist."

	// Server CA specific errors
	case serverCAOpenError = "Failed to open Server CA certificate file"
	case serverCAPasswordError = "Failed to open Server CA certificate. Wrong password?"
	case serverCANoCertificate = "Server CA file contains no certificates"
	case serverCAInvalidFormat = "Server CA file format is invalid. Use PEM, CRT, DER, or P12 format."
	case serverCANotSupported = "Server CA validation requires CocoaMQTT with serverCACertificates support. Use 'Allow untrusted' as a workaround."

	// Certificate availability errors (for multi-device sync)
	case clientCertMissing = "Client certificate not available on this device. Import the certificate in the broker settings."
	case clientCertMismatch = "Different client certificate on this device. The certificate file has changed. Import the correct certificate."
	case serverCAMissing = "Server CA certificate not available on this device. Import the certificate in the broker settings."
	case serverCAMismatch = "Different Server CA certificate on this device. The certificate file has changed. Import the correct certificate."
}

/// Validates that all configured certificates are available and match their expected hashes
/// - Parameter host: The host configuration to validate
/// - Throws: CertificateError if any certificate is missing or mismatched
func validateCertificateAvailability(host: Host) throws {
	// Check client P12 certificate
	if host.settings.authType == .certificate || host.settings.authType == .both {
		if let clientCert = getCertificate(host, type: .p12) {
			if clientCert.existsButDifferent() {
				throw CertificateError.clientCertMismatch
			}
			if !clientCert.exists() {
				throw CertificateError.clientCertMissing
			}
		}
	}

	// Check Server CA certificate (only when TLS is enabled and not allowing untrusted)
	if host.settings.ssl && !host.settings.untrustedSSL {
		if let serverCA = getCertificate(host, type: .serverCA) {
			if serverCA.existsButDifferent() {
				throw CertificateError.serverCAMismatch
			}
			if !serverCA.exists() {
				throw CertificateError.serverCAMissing
			}
		}
	}
}

private func getClientCertFromP12File(certificate: CertificateFile, certPassword: String) throws -> CFArray? {
	var url = try certificate.getBaseUrl(certificate: certificate)
	url.appendPathComponent(certificate.name)

	guard let p12Data = NSData(contentsOf: url) else {
		throw CertificateError.errorOpenFile
	}

	// Use kSecImportToMemoryOnly on macOS 15+ to avoid keychain issues on Mac Catalyst.
	// The identity stays in memory and can be used directly for TLS without keychain access.
	// Without this, errSecItemNotFound (-65554) occurs because the Network framework
	// can't find the identity in the keychain on Mac Catalyst.
	let options = createP12ImportOptions(password: certPassword)

	var items: CFArray?
	let securityError = SecPKCS12Import(p12Data, options, &items)

	guard securityError == errSecSuccess else {
		if securityError == errSecAuthFailed {
			throw CertificateError.errSecAuthFailed
		} else {
			throw CertificateError.errorOpenFile
		}
	}

	guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
		return nil
	}

	let dictionary = (theArray as NSArray).object(at: 0)
	guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
		throw CertificateError.noIdentify
	}

	return [identity] as CFArray
}

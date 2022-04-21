//
//  Certificate.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 21.04.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

func getCertificate(_ host: Host, type: CertificateFileType) -> CertificateFile? {
	return host.certificates.filter { $0.type == type }.first
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
}

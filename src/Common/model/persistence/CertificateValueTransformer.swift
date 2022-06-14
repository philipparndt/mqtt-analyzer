//
//  CertificateValueTransformer.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 14.06.22.
//  Copyright © 2022 Philipp Arndt. All rights reserved.
//

import Foundation

@objc(Certificates)
public class Certificates: NSObject {
	var files: [CertificateFile]
	
	init(_ files: [CertificateFile] = []) {
		self.files = files
	}
}

@objc(CertificateValueTransformer)
public final class CertificateValueTransformer: ValueTransformer {
	public override class func transformedValueClass() -> AnyClass {
		return Certificates.self
	}
	
	public override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	public override func transformedValue(_ value: Any?) -> Any? {
		guard let certificates = value as? Certificates else {
			return nil
		}
		
		return CertificateValueTransformer.encode(certificates: certificates.files)
	}
	
	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? Data else { return nil }
		
		return Certificates(CertificateValueTransformer.decode(certificates: data))
	}
		
	static func encode(certificates: [CertificateFile]) -> Data {
		 do {
			 return try JSONEncoder().encode(certificates)
		 } catch {
			 NSLog("Unexpected error encoding certificate files: \(error).")
			 return Data()
		 }
	}

	 static func decode(certificates: Data) -> [CertificateFile] {
		 do {
			 if certificates.isEmpty {
				 return []
			 }
			 
			 return try JSONDecoder().decode([CertificateFile].self, from: certificates)
		 } catch {
			 NSLog("Unexpected error decoding certificate files: \(error).")
			 return []
		 }
	 }
}



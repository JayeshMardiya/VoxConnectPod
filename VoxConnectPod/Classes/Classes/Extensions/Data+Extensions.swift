//
//  Data+Extensions.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

extension Data {
    
    func decode<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
    
    func toString(encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
    
    func decodeBase64Data() -> Self? {
        if let base64Data = Data(base64Encoded: self, options: .ignoreUnknownCharacters),
           let decodedString = String(data: base64Data, encoding: .utf8),
           let decodedData = decodedString.data(using: .utf8) {
            return decodedData
        }
        return nil
    }
    
    func mimeTypeForPath() -> String {
        
        var b: UInt8 = 0
        self.copyBytes(to: &b, count: 1)
        
        switch b {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x4D, 0x49:
            return "image/tiff"
        case 0x25:
            return "application/pdf"
        case 0xD0:
            return "application/vnd"
        case 0x46:
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
}

//
//  Encodable+Extensions.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

extension Encodable {
    
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    func toBase64Data() -> Data? {
        if let jsonData = self.toJSONData() {
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let base64String = jsonString.toBase64()
            return base64String.data(using: .utf8)!
        }
        
        return nil
    }
}

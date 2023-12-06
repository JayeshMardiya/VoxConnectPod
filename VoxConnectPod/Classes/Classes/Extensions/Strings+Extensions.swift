//
//  Strings+Extensions.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

public extension String {
    
    func toURL() -> URL {
        return URL(string: self)!
    }
    
    func toJSON() -> [String: Any]? {
        let data = self.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any> {
                return jsonArray
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

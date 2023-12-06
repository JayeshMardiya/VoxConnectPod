//
//  URLRequest+Extensions.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

private let AUTH_HEADER_FIELD = "Authorization"
private let CONTENT_TYPE_HEADER_FIELD = "ContentType"

extension URLRequest {
    mutating func setAuthHeader(_ authString: String) {
        self.setValue(authString, forHTTPHeaderField: AUTH_HEADER_FIELD)
    }
    
    mutating func setContentTypeJson() {
        self.setValue("application/json", forHTTPHeaderField: CONTENT_TYPE_HEADER_FIELD)
    }
}

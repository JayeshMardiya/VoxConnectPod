//
//  GenericError.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

struct GenericError: Error, LocalizedError {
    
    private let message: String
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return self.message
    }
}

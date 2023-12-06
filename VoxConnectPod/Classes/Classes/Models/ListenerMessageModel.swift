//
//  ListenerMessageModel.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

struct ListenerMessage: Codable {
    let id: String
    let username: String
    let message: String
    let isFavorite: Bool
    var timestamp: String?
}

//
//  AudioInfoModel.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

struct AudioInfo: Codable {
    
    let audio_id: Int
    let name: String
    let url: String
    let isPlaying: Bool?
}

//
//  WebSocketApiService.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import RxSwift

protocol WebSocketApiService {
    func getListenerCount(_ request: BroadcastStatsRequest) -> Single<BroadcastStatsResponse>
}

private enum EndPoint: String {
    case broadcast_stats = "https://%@/rest/v2/broadcasts/%@/broadcast-statistics"
    
    // http://52.91.238.198:5080
    
    func pathAtServer(_ server: String, withStreamId streamId: String) -> String {
        let serverAddress = server.replacingOccurrences(of: "wss://", with: "")
            .replacingOccurrences(of: "/websocket", with: "")
        return String(format: self.rawValue, serverAddress, streamId)
    }
    
    func urlAtServer(_ server: String, withStreamId streamId: String) -> URL {
        let path = self.pathAtServer(server, withStreamId: streamId)
        guard let url = URL(string: path) else {
            fatalError("Could not form URL from API path: \(path)")
        }
        return url
    }
}


class AntMediaApiServiceImpl: WebSocketApiService {
    
    let apiProvider = ApiProvider()
    
    func getListenerCount(_ request: BroadcastStatsRequest) -> Single<BroadcastStatsResponse> {
        let url = EndPoint.broadcast_stats.urlAtServer(request.serverAddress, withStreamId: request.streamId)
        return apiProvider.getRequest(url: url)
            .map { try $0.decode() }
            .catchAndReturn(BroadcastStatsResponse.idle)
    }
}

struct BroadcastStatsRequest: Codable {
    let serverAddress: String
    let streamId: String
}

struct BroadcastStatsResponse: Codable {
    let totalRTMPWatchersCount: Int
    let totalHLSWatchersCount: Int
    let totalWebRTCWatchersCount: Int
    
    static let idle = BroadcastStatsResponse(totalRTMPWatchersCount: 0, totalHLSWatchersCount: 0, totalWebRTCWatchersCount: 0)
}

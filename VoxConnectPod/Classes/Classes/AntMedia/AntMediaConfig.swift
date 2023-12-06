//
//  AntMediaConfig.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import WebRTC

class AntMediaConfig: NSObject {
    
    private let stunServer : String = "stun:stun.l.google.com:19302"
    private let constraints: [String: String] = ["OfferToReceiveAudio": "true",
                                                 "OfferToReceiveVideo": "true"]
    private let defaultConstraints: [String: String] = ["DtlsSrtpKeyAgreement": "true"]
    
    func defaultStunServer() -> RTCIceServer {
        let iceServer = RTCIceServer(urlStrings: [stunServer], username: "", credential: "")
        return iceServer
    }
    
    func createAudioVideoConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: defaultConstraints)
    }
    
    func createDefaultConstraint() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: defaultConstraints)
    }
    
    func createTestConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: constraints)
    }
    
    func createConfiguration(server: RTCIceServer) -> RTCConfiguration {
        let config = RTCConfiguration()
        config.iceServers = [server]
        return config
    }
}

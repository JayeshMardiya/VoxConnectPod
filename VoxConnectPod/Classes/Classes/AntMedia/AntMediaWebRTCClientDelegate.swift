//
//  AntMediaWebRTCClientDelegate.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import WebRTC

internal protocol AntMediaWebRTCClientDelegate {
    
    func sendMessage(_ message: [String: Any])
    
    func addRemoteStream()
    
    func addLocalStream()
    
    func connectionStateChanged(newState: RTCIceConnectionState);
    
    func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer);
}

//
//  ConferenceManager.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation

protocol ConferenceManagerDelegate: AnyObject {
    func currentListenerCount(listenerCount: Int)
    func playStarted(streamId: String)
    func playFinished(streamId: String)
    func didConnectToStream(streamId: String)
    func didDisConnectToStream(streamId: String)
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool)
}

class ConferenceManager {
    
    private let PUBLISHER_URL = "wss://dashboard.toursystems.guide:443/VoxConnect/websocket"
    private let PARTICIPANT_URL = "wss://dashboard.toursystems.guide:5443/VoxConnect/websocket"
    
    private var conferenceClient: ConferenceClient!
    private var broadcastingClient: AntMediaClient!
    private var receivingClients: [AntMediaClient] = []
    
    private lazy var serverUrl = {
        (self.userType == .presenter) ? PUBLISHER_URL : PARTICIPANT_URL
    }()
    
    private let roomName: String
    private let userType: UserType
    private let delegate: ConferenceManagerDelegate
    init(roomName: String, userType: UserType, delegate: ConferenceManagerDelegate) {
        self.roomName = roomName
        self.userType = userType
        self.delegate = delegate
    }
    
    func connect() {
        self.conferenceClient = ConferenceClient(serverURL: self.serverUrl,
                                                 conferenceClientDelegate: self,
                                                 userType: self.userType)
        self.conferenceClient.joinRoom(roomId: self.roomName, streamId: "")
    }
    
    func disconnect() {
        self.broadcastingClient?.stop()
        self.receivingClients.forEach { $0.stop() }
        self.conferenceClient.leaveRoom()
        self.receivingClients.removeAll()
    }
    
    func toggleAudio() {
        self.broadcastingClient?.toggleAudio()
        self.receivingClients.forEach { $0.toggleAudio() }
    }
    
    func muteIncommingAudio() {
        self.receivingClients.forEach { $0.muteIncomingAudio() }
    }
    
    func disableAudio() {
        self.receivingClients.first?.muteAudio()
    }
    
    /// Send Image/PDF
    func sendFile(message: PresenterMessage) {
        
        if let data = message.toBase64Data() {
            self.broadcastingClient.sendData(data: data, binary: false)
        }
    }
    
    func sendMessage(message: ListenerMessage) {
        if let data = message.toBase64Data() {
            self.receivingClients.first?.sendData(data: data, binary: false)
        }
    }
    
    /// Send Message
    func sendData(data: Data) {
        self.broadcastingClient.sendData(data: data, binary: false)
    }
    
    /// Send Message with Requesting creds
    func sendRequestCredsData(requestCreds: RequestCreds) {
        if let data = requestCreds.toBase64Data() {
            self.receivingClients.first?.sendData(data: data, binary: false)
        }
    }
    
    func sendAudioInfo(audioInfo: AudioInfo) {
        if let data = audioInfo.toBase64Data() {
            self.broadcastingClient.sendData(data: data, binary: false)
        }
    }
}

private extension ConferenceManager {
    
    func publishToStream(_ streamId: String) {
        Run.onMainThread {
            if self.userType != .presenter {
                return
            }
            
            self.broadcastingClient = AntMediaClient()
            self.broadcastingClient.delegate = self
            self.broadcastingClient.setOptions(url: self.serverUrl,
                                               streamId: streamId,
                                               token: "",
                                               mode: AntMediaClientMode.publish,
                                               enableDataChannel: true,
                                               userType: self.userType)
            self.broadcastingClient.initPeerConnection()
            self.broadcastingClient.start()
        }
    }
    
    func receiveFromStreams(_ streams: [String]) {
        Run.onMainThread {
            for stream in streams {
                AntMediaClient.printf("stream in the room: \(stream)")
                let playerClient = AntMediaClient()
                playerClient.delegate = self;
                playerClient.setOptions(url: self.serverUrl,
                                        streamId: stream,
                                        token: "",
                                        mode: AntMediaClientMode.play,
                                        enableDataChannel: true,
                                        userType: self.userType)
                self.receivingClients.append(playerClient)
                playerClient.initPeerConnection()
                playerClient.start()
            }
        }
    }
    
    func disconnectFromStreams(_ streams: [String]) {
        Run.onMainThread {
            var leftClientIndex:[Int] = []
            for streamId in streams {
                for (clientIndex, client) in self.receivingClients.enumerated() {
                    if (client.getStreamId() == streamId) {
                        client.stop();
                        leftClientIndex.append(clientIndex)
                        break;
                    }
                }
            }
            
            for index in leftClientIndex {
                self.receivingClients.remove(at: index);
            }
        }
    }
}

extension ConferenceManager : ConferenceClientDelegate {
    func streamIdToPublish(streamId: String) {
        self.publishToStream(streamId)
    }
    
    func newStreamsJoined(streams: [String]) {
        self.receiveFromStreams(streams)
    }
    
    func streamsLeft(streams: [String]) {
        self.disconnectFromStreams(streams)
    }
    
    func currentListenerCount(_ listenerCount: Int) {
        if self.userType == .presenter {
            self.delegate.currentListenerCount(listenerCount: listenerCount)
        }
    }
}

extension ConferenceManager : AntMediaClientDelegate {
    func clientDidConnect(_ client: AntMediaClient) {
        client.initPeerConnection()
        self.delegate.didConnectToStream(streamId: client.getStreamId())
    }
    
    func clientDidDisconnect(_ message: String) { }
    
    func clientHasError(_ message: String) { }
    
    func remoteStreamStarted(streamId: String) { }
    
    func remoteStreamRemoved(streamId: String) { }
    
    func localStreamStarted(streamId: String) { }
    
    func playStarted(streamId: String) {
        self.delegate.playStarted(streamId: streamId)
    }
    
    func playFinished(streamId: String) {
        self.delegate.playFinished(streamId: streamId)
    }
    
    func publishStarted(streamId: String) { }
    
    func publishFinished(streamId: String) { }
    
    func disconnected(streamId: String) {
        self.delegate.didDisConnectToStream(streamId: streamId)
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) { }
    
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        if let base64Data = data.decodeBase64Data() {
            self.delegate.dataReceivedFromDataChannel(streamId: streamId, data: base64Data, binary: binary)
        }
    }
    
    func streamInformation(streamInfo: [StreamInformation]) { }
}

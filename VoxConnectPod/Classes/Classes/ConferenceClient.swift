//
//  ConferenceClient.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import Starscream
import RxSwift

public protocol ConferenceClientProtocol {
    
    /**
     Join the room
     - roomId: the id of the room that conference client joins
     - streamId: the preferred stream id that can be sent to the server for publishing. Server likely responds the same streamId in
     delegate's streamIdToPublish method
     */
    func joinRoom(roomId: String, streamId: String)
    
    /*
     Leave the room
     */
    func leaveRoom();
}

public protocol ConferenceClientDelegate {
    /**
     It's called after join to the room.
     - streamId: the id of the stream tha can be used to publish stream.
     It's not an obligation to publish a stream. It changes according to the project
     */
    func streamIdToPublish(streamId: String);
    
    /**
     Called when new streams join to the room. So that  they can be played
     - streams:  stream id array of the streams that join to the room
     */
    func newStreamsJoined(streams: [String]);
    
    /**
     Called when some streams leaves from the room. So that players can be removed from the user interface
     - streams: stream id array of the stream that leaves from the room
     */
    func streamsLeft(streams: [String]);
    
    func currentListenerCount(_ listenerCount: Int)
}

open class ConferenceClient: ConferenceClientProtocol {
    
    var serverURL: String
    var webSocket: WebSocket
    var roomId: String!
    var streamId: String?
    
    var streamsInTheRoom: [String] = []
    private let delegate: ConferenceClientDelegate
    var userType: UserType?
    private let apiService = AntMediaApiServiceImpl()
    private var disposeBag = DisposeBag()
    
    public init(serverURL: String, conferenceClientDelegate: ConferenceClientDelegate, userType: UserType) {
        self.serverURL = serverURL;
        self.userType = userType
        self.delegate = conferenceClientDelegate
        
        var request = URLRequest(url: URL(string: self.serverURL)!)
        request.timeoutInterval = 5
        webSocket = WebSocket(request: request)
        webSocket.delegate = self
        
        // Get Listener Count every 5 seconds
        Observable<Int>
            .interval(RxTimeInterval.seconds(5), scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Int> in
                guard let streamId = self.streamId else {
                    return Observable.just(0)
                }
                
                let request = BroadcastStatsRequest(serverAddress: self.serverURL, streamId: streamId)
                return self.apiService.getListenerCount(request)
                    .map { $0.totalWebRTCWatchersCount }
                    .map { $0 <= 0 ? 0 : $0 }
                    .asObservable()
            }
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] count in
                    self?.delegate.currentListenerCount(count)
                    self?.requestRoomInfo()
                },
                onError: { error in
                    print(error.localizedDescription)
                }
            ).disposed(by: disposeBag)
    }
    
    deinit {}
    
    public func joinRoom(roomId: String, streamId: String) {
        self.roomId = roomId;
        self.streamId = streamId;
        webSocket.connect()
    }
    
    public func leaveRoom() {
        self.disposeBag = DisposeBag()
        let leaveRoomMessage =  [
            COMMAND: CMD_LEAVE_ROOM,
            ROOM_ID: self.roomId!,
            STREAM_ID: self.streamId ?? "" ] as [String : Any]
        
        webSocket.write(string: leaveRoomMessage.json)
        self.webSocket.disconnect()
    }
}

extension ConferenceClient : WebSocketDelegate {
    public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        
        switch event {
        case .connected(_):
            self.sendJoinRoomCommand()
            
        case .disconnected(let reason, let code):
            AntMediaClient.printf("websocket is disconnected: \(reason) with code: \(code)")
            
        case .text(let message):
            self.handleWebsocketResponse(message: message)
            
        case .binary(let data):
            AntMediaClient.printf("Received data: \(data.count)")
            
        case .error(let error):
            // TODO: Handle Error
            AntMediaClient.printf("Error occured on websocket connection \(String(describing: error))");
            
        default:
            AntMediaClient.printf("Error occured on websocket connection \(event)");
        }
    }
}

private extension ConferenceClient {
    
    func sendJoinRoomCommand() {
        let joinRoomMessage =  [
            COMMAND: CMD_JOIN_ROOM,
            ROOM_ID: self.roomId!,
            STREAM_ID: self.streamId ?? ""
        ] as [String : Any]
        
        webSocket.write(string: joinRoomMessage.json)
    }
    
    func requestRoomInfo() {
        let message =  [
            COMMAND: CMD_GET_ROOM_INFO,
            ROOM_ID: self.roomId!,
            STREAM_ID: self.streamId ?? "" ] as [String : Any]
        
        webSocket.write(string: message.json)
    }
    
    func handleWebsocketResponse(message: String) {
        if let message = message.toJSON() {
            guard let command = message[COMMAND] as? String else {
                return
            }
            
            switch command {
            case NOTIFICATION:
                guard let definition = message[DEFINITION] as? String else {
                    return
                }
                
                if definition == JOINED_ROOM_DEFINITION {
                    if let streamId = message[STREAM_ID] as? String {
                        self.streamId = streamId
                        self.delegate.streamIdToPublish(streamId: streamId);
                    }
                    
                    if let streams = message[STREAMS] as? [String] {
                        self.streamsInTheRoom = streams;
                        self.delegate.newStreamsJoined(streams:  streams);
                    }
                }
                
            case RESP_GET_ROOM_INFO:
                if let updatedStreamsInTheRoom = message[STREAMS] as? [String] {
                    //check that there is a new stream exists
                    var newStreams:[String] = []
                    var leavedStreams: [String] = []
                    
                    for stream in updatedStreamsInTheRoom {
                        // AntMedia.printf("stream in updatestreamInTheRoom \(stream)")
                        if (!self.streamsInTheRoom.contains(stream)) {
                            newStreams.append(stream)
                        }
                    }
                    //check that any stream is leaved
                    for stream in self.streamsInTheRoom {
                        if (!updatedStreamsInTheRoom.contains(stream)) {
                            leavedStreams.append(stream)
                        }
                    }
                    
                    self.streamsInTheRoom = updatedStreamsInTheRoom
                    
                    if (newStreams.count > 0) {
                        self.delegate.newStreamsJoined(streams: newStreams)
                    }
                    
                    if (leavedStreams.count > 0) {
                        self.delegate.streamsLeft(streams: leavedStreams)
                    }
                }
                
                break;
            default:
                print(command)
            }
        } else {
            print("WebSocket message JSON parsing error: " + message)
        }
    }
}

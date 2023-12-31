//
//  AntMediaWebRTCClient.swift
//  VoxConnectLib
//
//  Created by Jayesh Mardiya on 06/12/23.
//

import Foundation
import AVFoundation
import WebRTC
import ReplayKit

class AntMediaWebRTCClient: NSObject {
    
    let VIDEO_TRACK_ID = "VIDEO"
    let AUDIO_TRACK_ID = "AUDIO"
    let LOCAL_MEDIA_STREAM_ID = "STREAM"
    
    private var audioDeviceModule: RTCAudioDeviceModule? = nil;
    private static var factory: RTCPeerConnectionFactory! = nil;
    
    var delegate: AntMediaWebRTCClientDelegate?
    var peerConnection : RTCPeerConnection?
    
    private var videoCapturer: RTCVideoCapturer?
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var remoteVideoView: RTCVideoRenderer?
    var localVideoView: RTCVideoRenderer?
    var videoSender: RTCRtpSender?
    var dataChannel: RTCDataChannel?
    private var enableDataChannel: Bool = true;
    
    private var token: String!
    private var streamId: String!
    private var userType: UserType = .listener
    
    private var audioEnabled: Bool = true
    private var videoEnabled: Bool = true
    private var captureScreenEnabled: Bool = false;
    private var config = AntMediaConfig()
    private var mode: AntMediaClientMode = AntMediaClientMode.join
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    private var externalVideoCapture: Bool = false;
    private var externalAudio: Bool = false;
    
    private var targetWidth: Int = 480
    private var targetHeight: Int = 360
    
    public init(remoteVideoView: RTCVideoRenderer?,
                localVideoView: RTCVideoRenderer?,
                delegate: AntMediaWebRTCClientDelegate) {
        
        super.init()
        
        self.remoteVideoView = remoteVideoView
        self.localVideoView = localVideoView
        self.delegate = delegate
        
        RTCPeerConnectionFactory.initialize()
        
        self.externalAudio = true;
        if (externalAudio) {
            self.audioDeviceModule = RTCAudioDeviceModule();
        }
        
        AntMediaWebRTCClient.factory = initFactory();
        
        let stunServer = config.defaultStunServer()
        let defaultConstraint = config.createDefaultConstraint()
        let configuration = config.createConfiguration(server: stunServer)
        
        self.peerConnection = AntMediaWebRTCClient.factory.peerConnection(with: configuration, constraints: defaultConstraint, delegate: self)
    }
    
    private func initFactory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        if (audioDeviceModule == nil) {
            return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory,
                                            decoderFactory: videoDecoderFactory)
        }
        else {
            return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory,
                                            decoderFactory: videoDecoderFactory,
                                            audioDeviceModule: audioDeviceModule!)
        }
    }
    
    public convenience init(remoteVideoView: RTCVideoRenderer?,
                            localVideoView: RTCVideoRenderer?,
                            delegate: AntMediaWebRTCClientDelegate,
                            mode: AntMediaClientMode,
                            cameraPosition: AVCaptureDevice.Position,
                            targetWidth: Int,
                            targetHeight: Int,
                            userType: UserType) {
        
        self.init(remoteVideoView: remoteVideoView,
                  localVideoView: localVideoView,
                  delegate: delegate,
                  mode: mode,
                  cameraPosition: cameraPosition,
                  targetWidth: targetWidth,
                  targetHeight: targetHeight,
                  videoEnabled: true,
                  multiPeerActive:false,
                  enableDataChannel: false,
                  userType: userType)
    }
    
    public convenience init(remoteVideoView: RTCVideoRenderer?,
                            localVideoView: RTCVideoRenderer?,
                            delegate: AntMediaWebRTCClientDelegate,
                            mode: AntMediaClientMode,
                            cameraPosition: AVCaptureDevice.Position,
                            targetWidth: Int,
                            targetHeight: Int,
                            videoEnabled: Bool,
                            multiPeerActive: Bool,
                            enableDataChannel: Bool,
                            userType: UserType) {
        
        self.init(remoteVideoView: remoteVideoView,
                  localVideoView: localVideoView,
                  delegate: delegate,
                  mode: mode,
                  cameraPosition: cameraPosition,
                  targetWidth: targetWidth,
                  targetHeight: targetHeight,
                  videoEnabled: true,
                  multiPeerActive:false,
                  enableDataChannel: false,
                  captureScreen: false,
                  userType: userType)
    }
    
    public convenience init(remoteVideoView: RTCVideoRenderer?,
                            localVideoView: RTCVideoRenderer?,
                            delegate: AntMediaWebRTCClientDelegate,
                            mode: AntMediaClientMode,
                            cameraPosition: AVCaptureDevice.Position,
                            targetWidth: Int,
                            targetHeight: Int,
                            videoEnabled: Bool,
                            multiPeerActive: Bool,
                            enableDataChannel: Bool,
                            captureScreen: Bool,
                            userType: UserType) {
        
        self.init(remoteVideoView: remoteVideoView,
                  localVideoView: localVideoView,
                  delegate: delegate)
        
        self.mode = mode
        self.cameraPosition = cameraPosition
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.videoEnabled = videoEnabled
        self.captureScreenEnabled = captureScreen
        self.userType = userType
        self.enableDataChannel = enableDataChannel
        if (self.mode != .play && !multiPeerActive) {
            if userType != .listener {
                //                self.addLocalMediaStream()
            }
            
            self.addLocalMediaStream()
        }
    }
    
    public func externalVideoCapture(externalVideoCapture: Bool) {
        self.externalVideoCapture = externalVideoCapture;
    }
    
    public func setMaxVideoBps(maxVideoBps:NSNumber) {
        AntMediaClient.printf("In setMaxVideoBps:\(maxVideoBps)")
        if (maxVideoBps.intValue > 0) {
            AntMediaClient.printf("setMaxVideoBps:\(maxVideoBps)")
            self.peerConnection?.setBweMinBitrateBps(nil, currentBitrateBps: nil, maxBitrateBps: maxVideoBps)
        }
    }
    
    public func getStats(handler: @escaping (RTCStatisticsReport) -> Void) {
        self.peerConnection?.statistics(completionHandler: handler);
    }
    
    public func setStreamId(_ streamId: String) {
        self.streamId = streamId
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    
    public func setRemoteDescription(_ description: RTCSessionDescription) {
        self.peerConnection?.setRemoteDescription(description, completionHandler: {
            (error) in
            if (error != nil) {
                AntMediaClient.printf("Error (setRemoteDescription): " + error!.localizedDescription + " debug description: " + error.debugDescription)
                
            }
        })
    }
    
    public func addCandidate(_ candidate: RTCIceCandidate) {
        self.peerConnection?.add(candidate, completionHandler: { error in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    public func sendData(data: Data, binary: Bool = false) {
        if (self.dataChannel?.readyState == .open) {
            let dataBuffer = RTCDataBuffer.init(data: data, isBinary: binary);
            self.dataChannel?.sendData(dataBuffer);
        } else {
            AntMediaClient.printf("Data channel is nil or state is not open. State is \(String(describing: self.dataChannel?.readyState)) Please check that data channel is enabled in server side ")
        }
    }
    
    public func isDataChannelActive() -> Bool {
        return self.dataChannel?.readyState == .open;
    }
    
    public func sendAnswer() {
        let constraint = self.config.createAudioVideoConstraints()
        self.peerConnection?.answer(for: constraint, completionHandler: { (sdp, error) in
            if (error != nil) {
                AntMediaClient.printf("Error (sendAnswer): " + error!.localizedDescription)
            } else {
                AntMediaClient.printf("Got your answer")
                if (sdp?.type == RTCSdpType.answer) {
                    self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                        (error) in
                        if (error != nil) {
                            AntMediaClient.printf("Error (sendAnswer/closure): " + error!.localizedDescription)
                        }
                    })
                    
                    var answerDict = [String: Any]()
                    
                    if (self.token.isEmpty) {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!] as [String : Any]
                    } else {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!,
                                       "token": self.token ?? ""] as [String : Any]
                    }
                    
                    self.delegate?.sendMessage(answerDict)
                }
            }
        })
    }
    
    public func createOffer() {
        
        //let the one who creates offer also create data channel.
        //by doing that it will work both in publish-play and peer-to-peer mode
        if (enableDataChannel) {
            self.dataChannel = createDataChannel()
            self.dataChannel?.delegate = self
        }
        
        let constraint = self.config.createAudioVideoConstraints()
        
        self.peerConnection?.offer(for: constraint, completionHandler: { (sdp, error) in
            if (sdp?.type == RTCSdpType.offer) {
                AntMediaClient.printf("Got your offer")
                
                self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                    (error) in
                    if (error != nil) {
                        AntMediaClient.printf("Error (createOffer): " + error!.localizedDescription)
                    }
                })
                
                AntMediaClient.printf("offer sdp: " + sdp!.sdp)
                var offerDict = [String: Any]()
                
                if (self.token.isEmpty) {
                    offerDict =  ["type": "offer",
                                  "command": "takeConfiguration",
                                  "sdp": sdp!.sdp,
                                  "streamId": self.streamId!] as [String : Any]
                } else {
                    offerDict =  ["type": "offer",
                                  "command": "takeConfiguration",
                                  "sdp": sdp!.sdp,
                                  "streamId": self.streamId!,
                                  "token": self.token ?? ""] as [String : Any]
                }
                
                self.delegate?.sendMessage(offerDict)
            }
        })
    }
    
    public func stop() {
        disconnect();
    }
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        config.channelId = 0
        guard let dataChannel = self.peerConnection?.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            AntMediaClient.printf("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    public func disconnect() {
        //TODO: how to clear all resources
        //  self.localVideoTrack?.remove(self.localVideoView!)
        self.remoteVideoTrack?.remove(self.remoteVideoView!)
        //  self.localVideoView?.renderFrame(nil)
        self.remoteVideoView?.renderFrame(nil)
        self.localVideoTrack = nil
        self.remoteVideoTrack = nil
        
        if self.videoCapturer is RTCCameraVideoCapturer {
            (self.videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
        } else if self.videoCapturer is RTCCustomFrameCapturer {
            (self.videoCapturer as? RTCCustomFrameCapturer)?.stopCapture()
        }
        
        self.peerConnection?.close()
    }
    
    public func muteIncomingAudio() {
        self.audioEnabled = false
        self.localAudioTrack?.isEnabled = false
    }
    
    public func toggleAudioEnabled() {
        self.audioEnabled = !self.audioEnabled
        if (self.localAudioTrack != nil) {
            self.localAudioTrack.isEnabled = self.audioEnabled
        }
    }
    
    public func toggleVideoEnabled() {
        self.videoEnabled = !self.videoEnabled
        if(self.localVideoTrack != nil) {
            self.localVideoTrack.isEnabled = self.videoEnabled
        }
    }
    
    private func startCapture() -> Bool {
        
        let camera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == self.cameraPosition })
        
        if (camera != nil) {
            let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: camera!)
            var currentDiff = INT_MAX
            var selectedFormat: AVCaptureDevice.Format? = nil
            for supportedFormat in supportedFormats {
                let dimension = CMVideoFormatDescriptionGetDimensions(supportedFormat.formatDescription)
                let diff = abs(Int32(targetWidth) - dimension.width) + abs(Int32(targetHeight) - dimension.height);
                if (diff < currentDiff) {
                    selectedFormat = supportedFormat
                    currentDiff = diff
                }
            }
            
            if (selectedFormat != nil) {
                
                var maxSupportedFramerate: Float64 = 0;
                for fpsRange in selectedFormat!.videoSupportedFrameRateRanges {
                    maxSupportedFramerate = fmax(maxSupportedFramerate, fpsRange.maxFrameRate);
                }
                let fps = fmin(maxSupportedFramerate, 30.0);
                
                let dimension = CMVideoFormatDescriptionGetDimensions(selectedFormat!.formatDescription)
                
                AntMediaClient.printf("Camera resolution: " + String(dimension.width) + "x" + String(dimension.height)
                                      + " fps: " + String(fps))
                
                let cameraVideoCapturer = self.videoCapturer as? RTCCameraVideoCapturer;
                
                
                cameraVideoCapturer?.startCapture(with: camera!,
                                                  format: selectedFormat!,
                                                  fps: Int(fps))
                return true
            } else {
                AntMediaClient.printf("Cannot open camera not suitable format")
            }
        } else {
            AntMediaClient.printf("Not Camera Found")
        }
        
        return false;
    }
    
    private func createVideoTrack() -> RTCVideoTrack?  {
        let videoSource = AntMediaWebRTCClient.factory.videoSource()
        
        if captureScreenEnabled {
            self.videoCapturer = RTCCustomFrameCapturer(delegate: videoSource, height: targetHeight)
            (self.videoCapturer as? RTCCustomFrameCapturer)?.startCapture()
        } else {
            #if TARGET_OS_SIMULATOR
                self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
            #else
                self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
                let captureStarted = startCapture()
                if (!captureStarted) {
                    return nil;
                }
            #endif
        }
        
        let videoTrack = AntMediaWebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    private func addLocalMediaStream() {
        
        AntMediaClient.printf("Add local media streams")
        
        if (self.videoEnabled) {
            self.localVideoTrack = createVideoTrack();
            self.videoSender = self.peerConnection?.add(self.localVideoTrack,  streamIds: [LOCAL_MEDIA_STREAM_ID])
        }
        
        if self.userType == .presenter {
            let audioSource = AntMediaWebRTCClient.factory.audioSource(with: self.config.createTestConstraints())
            self.localAudioTrack = AntMediaWebRTCClient.factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
            self.peerConnection?.add(self.localAudioTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
        }
        
        if (self.localVideoTrack != nil) {
            self.localVideoTrack.add(localVideoView!)
        }
        self.delegate?.addLocalStream()
    }
    
    public func switchCamera() {
        
        if let sender = self.videoSender {
            peerConnection?.removeTrack(sender)
        }
        
        if self.cameraPosition == .front {
            self.cameraPosition = .back
        } else {
            self.cameraPosition = .front
        }
        
        self.localVideoTrack.remove(localVideoView!)
        self.localVideoTrack = createVideoTrack()
        
        self.localVideoTrack.add(localVideoView!)
        
        self.videoSender = self.peerConnection?.add(self.localVideoTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
    }
    
    public func deliverExternalAudio(sampleBuffer: CMSampleBuffer) {
        self.audioDeviceModule?.deliverRecordedData(sampleBuffer)
    }
    
    public func getVideoCapturer() -> RTCVideoCapturer? {
        return videoCapturer;
    }
}

extension AntMediaWebRTCClient: RTCDataChannelDelegate {
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.dataReceivedFromDataChannel(didReceiveData: buffer)
    }
    
    func dataChannelDidChangeState(_ parametersdataChannel: RTCDataChannel)  {
        if (parametersdataChannel.readyState == .open) {
            AntMediaClient.printf("Data channel state is open")
        } else if  (parametersdataChannel.readyState == .connecting) {
            AntMediaClient.printf("Data channel state is connecting")
        } else if  (parametersdataChannel.readyState == .closing) {
            AntMediaClient.printf("Data channel state is closing")
        } else if  (parametersdataChannel.readyState == .closed) {
            AntMediaClient.printf("Data channel state is closed")
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        print("Buffer Amount: \(amount)")
    }
}

extension AntMediaWebRTCClient: RTCPeerConnectionDelegate {
    
    // signalingStateChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //AntMediaClient.printf("---> StateChanged:\(stateChanged.rawValue)")
    }
    
    // addedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        AntMediaClient.printf("AddedStream")
        
        self.localAudioTrack = stream.audioTracks.first
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            return
        }
        
        if (stream.videoTracks.count == 1) {
            AntMediaClient.printf("stream has video track");
            if (remoteVideoView != nil) {
                remoteVideoTrack = stream.videoTracks[0]
                
                //remoteVideoTrack.setEnabled(true)
                remoteVideoTrack.add(remoteVideoView!)
                AntMediaClient.printf("Has delegate??? (signalingStateChanged): \(String(describing: self.delegate))")
            }
            delegate?.addRemoteStream()
        } else {
            
        }
    }
    
    // removedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        AntMediaClient.printf("RemovedStream")
        remoteVideoTrack = nil
        remoteAudioTrack = nil
    }
    
    // GotICECandidate
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateJson = ["command": "takeCandidate",
                             "type" : "candidate",
                             "streamId": self.streamId ?? "",
                             "candidate" : candidate.sdp,
                             "label": candidate.sdpMLineIndex,
                             "id": candidate.sdpMid ?? ""] as [String : Any]
        self.delegate?.sendMessage(candidateJson)
    }
    
    // iceConnectionChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        AntMediaClient.printf("---> iceConnectionChanged: \(newState.rawValue) for stream: \(self.streamId ?? "")")
        self.delegate?.connectionStateChanged(newState: newState)
    }
    
    // iceGatheringChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //AntMediaClient.printf("---> iceGatheringChanged")
    }
    
    // didOpen dataChannel
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        AntMediaClient.printf("---> dataChannel opened")
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //AntMediaClient.printf("---> peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //AntMediaClient.printf("---> didRemove")
    }
}

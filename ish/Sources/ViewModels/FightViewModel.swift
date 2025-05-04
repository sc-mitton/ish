import Foundation
import WebRTC

class FightViewModel: ObservableObject {
    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    private let friend: Friend

    @Published var connectionStatus: String = "Connecting..."
    @Published var isConnected = false
    @Published var errorMessage: String?

    init(signalClient: SignalingClient, webRTCClient: WebRTCClient, friend: Friend) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        self.friend = friend

        setupSignaling()
        setupWebRTC()
    }

    private func setupSignaling() {
        signalClient.delegate = self
    }

    private func setupWebRTC() {
        webRTCClient.delegate = self
    }

    func startFight() {
        let fightId = UUID().uuidString

        signalClient.connect()

        if isConnected {
            webRTCClient.offer { [weak self] offer in
                self?.signalClient.send(sdp: offer)
            }
        }
    }

    func endFight() {
        // Clean up WebRTC connection and end the fight
    }
}

extension FightViewModel: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        connectionStatus = "Connected"
        isConnected = true
    }

    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        connectionStatus = "Disconnected"
        errorMessage = "Lost connection to opponent"
        isConnected = false
    }

    func signalClient(
        _ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription
    ) {
        // Handle received SDP
        webRTCClient.set(remoteSdp: sdp) { [weak self] error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func signalClient(
        _ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate
    ) {
        // Handle received ICE candidate
        webRTCClient.set(remoteCandidate: candidate)
    }
}

extension FightViewModel: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    {
        signalClient.send(candidate: candidate)
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    {
        switch state {
        case .connected:
            connectionStatus = "Connected"
            isConnected = true
        case .disconnected:
            connectionStatus = "Disconnected"
            errorMessage = "Lost connection to opponent"
            isConnected = false
        case .failed:
            connectionStatus = "Failed"
            errorMessage = "Connection failed"
            isConnected = false
        default:
            break
        }
    }

    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        // Handle received data (fight moves, etc.)
    }
}

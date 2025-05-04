import Foundation
import SwiftUI
import WebRTC

struct FightInitiationView: View {
    let friend: Friend
    let signalClient: SignalingClient
    let webRTCClient: WebRTCClient
    let supabaseService: SupabaseService

    @State private var fightId: String = ""
    @State private var connectionStatus: String = "Connecting..."
    @State private var isConnected = false
    @State private var errorMessage: String?
    @State private var showFightView = false
    @State private var isConnecting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Initiating fight with \(friend.username)")
                    .font(.headline)
                    .padding(.bottom, 20)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Text(connectionStatus)
                    .foregroundColor(isConnected ? .green : .orange)
                    .padding()

                if isConnecting {
                    ProgressView()
                        .padding()
                }

                if isConnected {
                    Button(action: { showFightView = true }) {
                        Text("Start Fight")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationBarTitle("Fight Initiation", displayMode: .inline)
            .onAppear { initiateFight() }
        }
    }

    private func initiateFight() {
        isConnecting = true
        Task {
            do {
                fightId = UUID().uuidString
                signalClient.connect()

                // Set up signaling delegate
                signalClient.delegate = SignalClientDelegateAdapter(
                    onConnect: {
                        connectionStatus = "Connected"
                        isConnected = true
                        isConnecting = false
                    },
                    onDisconnect: {
                        connectionStatus = "Friend is unreachable"
                        errorMessage = "Your friend could not be reached. They may be offline."
                        isConnected = false
                        isConnecting = false
                    },
                    onSdp: { sdp in
                        Task {
                            do {
                                try await webRTCClient.set(remoteSdp: sdp)
                            } catch {
                                errorMessage =
                                    "Failed to set remote SDP: \(error.localizedDescription)"
                            }
                        }
                    },
                    onCandidate: { candidate in
                        webRTCClient.set(remoteCandidate: candidate)
                    }
                )

                // Set up WebRTC delegate
                webRTCClient.delegate = WebRTCClientDelegateAdapter(
                    onLocalCandidate: { candidate in
                        signalClient.send(candidate: candidate)
                    },
                    onConnectionStateChange: { state in
                        switch state {
                        case .connected:
                            connectionStatus = "Connected"
                            isConnected = true
                            isConnecting = false
                        case .disconnected:
                            connectionStatus = "Disconnected"
                            errorMessage = "Lost connection to opponent"
                            isConnected = false
                            isConnecting = false
                        case .failed:
                            connectionStatus = "Failed"
                            errorMessage = "Connection failed"
                            isConnected = false
                            isConnecting = false
                        default:
                            break
                        }
                    }
                )

                // Create and send offer when connected
                if isConnected {
                    try await webRTCClient.offer { offer in
                        signalClient.send(sdp: offer)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                isConnecting = false
            }
        }
    }
}

// Helper class to adapt WebRTC delegate methods
class WebRTCClientDelegateAdapter: WebRTCClientDelegate {
    private let onLocalCandidate: (RTCIceCandidate) -> Void
    private let onConnectionStateChange: (RTCIceConnectionState) -> Void

    init(
        onLocalCandidate: @escaping (RTCIceCandidate) -> Void,
        onConnectionStateChange: @escaping (RTCIceConnectionState) -> Void
    ) {
        self.onLocalCandidate = onLocalCandidate
        self.onConnectionStateChange = onConnectionStateChange
    }

    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    {
        onLocalCandidate(candidate)
    }

    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    {
        onConnectionStateChange(state)
    }

    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        // Handle received data if needed
    }
}

class SignalClientDelegateAdapter: SignalClientDelegate {
    private let onConnect: () -> Void
    private let onDisconnect: () -> Void
    private let onSdp: (RTCSessionDescription) -> Void
    private let onCandidate: (RTCIceCandidate) -> Void

    init(
        onConnect: @escaping () -> Void,
        onDisconnect: @escaping () -> Void,
        onSdp: @escaping (RTCSessionDescription) -> Void,
        onCandidate: @escaping (RTCIceCandidate) -> Void
    ) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onSdp = onSdp
        self.onCandidate = onCandidate
    }

    func signalClientDidConnect(_ signalClient: SignalingClient) {
        onConnect()
    }

    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        onDisconnect()
    }

    func signalClient(
        _ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription
    ) {
        onSdp(sdp)
    }

    func signalClient(
        _ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate
    ) {
        onCandidate(candidate)
    }
}

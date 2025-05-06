import Foundation
import Supabase
import WebRTC

protocol SignalClientDelegate: AnyObject {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didTimeout waitingForConnection: Bool)
    func signalClient(_ signalClient: SignalingClient, didError error: Error)
}

final class SignalingClient {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let supabase: SupabaseService
    private let userId: String
    private var channelId: String = ""
    private var channel: RealtimeChannelV2!
    private var connectionTimeoutTimer: Timer?
    private let connectionTimeoutInterval: TimeInterval = 30  // 30 seconds timeout
    weak var delegate: SignalClientDelegate?

    init(supabase: SupabaseService) {
        self.supabase = supabase
        let userId = supabase.client.auth.currentUser?.id.uuidString
        guard let userId = userId else {
            fatalError("User ID is nil")
        }
        self.userId = userId
    }

    func joinMeeting(_ meeting: Meeting) async {
        self.channelId = meeting.id
        await self.supabase.openSocketChannel(self.channelId)
        startConnectionTimeoutTimer()
    }

    func joinMeeting(with userId: String) async {
        self.channelId = UUID().uuidString
        let meeting = Meeting(from: self.userId, to: userId, id: self.channelId)
        await self.supabase.openSocketChannel(meeting.id)
        startConnectionTimeoutTimer()
        await notifyUser(meeting: meeting)
    }

    func notifyUser(meeting: Meeting) async {
        // Send initial meeting request via HTTP
        let meeting = Meeting(from: self.userId, to: userId, id: self.channelId)
        do {
            let data = try self.encoder.encode(meeting)
            guard
                let serverURLString = Bundle.main.object(forInfoDictionaryKey: "SERVER_URL")
                    as? String,
                let url = URL(string: serverURLString)
            else {
                throw SignalingError.invalidServerURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SignalingError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw SignalingError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch {
            delegate?.signalClient(self, didError: error)
            return
        }
    }

    private func startConnectionTimeoutTimer() {
        // Cancel any existing timer
        connectionTimeoutTimer?.invalidate()

        // Create new timer
        connectionTimeoutTimer = Timer.scheduledTimer(
            withTimeInterval: connectionTimeoutInterval, repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }
            self.handleConnectionTimeout()
        }
    }

    private func handleConnectionTimeout() {
        delegate?.signalClient(self, didTimeout: true)
        closeConnection()
    }

    private func closeConnection() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
        channelId = ""
        channel = nil
        delegate?.signalClientDidDisconnect(self)
    }
}

extension SignalingClient: SupabaseServiceDelegate {
    func broadcasted(_ supabaseService: SupabaseService, didReceiveData data: JSONObject) {
        self.handleReceivedData(data)
    }

    func broadcastChannelOpened(_ supabaseService: SupabaseService) {
        self.delegate?.signalClientDidConnect(self)
    }

    func broadcastChannelClosed(_ supabaseService: SupabaseService) {
        closeConnection()
    }

    func handleReceivedData(_ data: JSONObject) {
        let message = try! self.decoder.decode(
            Message.self, from: JSONSerialization.data(withJSONObject: data))

        switch message {
        case .candidate(let iceCandidate):
            print("send back candidates")
        case .sdp(let sessionDescription):
            print("send answer")
        case .joined(let joinedAck):
            print("send offer")
        }
    }
}

enum SignalingError: LocalizedError {
    case invalidServerURL
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL configuration"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}

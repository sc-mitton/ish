import Foundation
import WebRTC

class FightInitiationViewModel: ObservableObject {
    private let friend: User
    private let signalClient: SignalingClient
    private let meeting: Meeting?

    @Published var isConnecting = false
    @Published var broadcasting = false
    @Published var errorMessage: String?
    @Published var hasTimedOut = false

    init(signalClient: SignalingClient, friend: User, meeting: Meeting?) {
        self.friend = friend
        self.signalClient = signalClient
        self.meeting = meeting
        self.signalClient.delegate = self
    }

    func connect() async {
        guard !isConnecting else { return }

        isConnecting = true
        errorMessage = nil
        hasTimedOut = false

        if let meeting = meeting {
            await signalClient.joinMeeting(meeting)
        } else {
            await signalClient.joinMeeting(with: friend.id.uuidString)
        }
    }

    func cancelMeeting() {
        isConnecting = false
        hasTimedOut = false
        errorMessage = nil
    }
}

extension FightInitiationViewModel: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        broadcasting = true
        isConnecting = false
    }

    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        broadcasting = false
        if !hasTimedOut {
            isConnecting = false
        }
    }

    func signalClient(_ signalClient: SignalingClient, didTimeout waitingForConnection: Bool) {
        hasTimedOut = true
        isConnecting = false
        errorMessage = "Connection timed out. \(friend.username) did not respond."
    }

    func signalClient(_ signalClient: SignalingClient, didError error: Error) {
        isConnecting = false
        errorMessage = error.localizedDescription
    }
}

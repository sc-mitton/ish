import Foundation
import Supabase
import SwiftUI
import WebRTC

struct FightInitiationView: View {
    let signalClient: SignalingClient
    let friend: User
    let meeting: Meeting?
    let supabaseService = SupabaseService.shared

    @StateObject private var viewModel: FightInitiationViewModel

    init(signalClient: SignalingClient, friend: User, meeting: Meeting?) {
        self.signalClient = signalClient
        self.meeting = meeting
        self.friend = friend

        self._viewModel = StateObject(
            wrappedValue: FightInitiationViewModel(
                signalClient: signalClient,
                friend: friend,
                meeting: meeting
            ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isConnecting {
                    ProgressView("Connecting to \(friend.username)...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Try Again") {
                            Task {
                                await viewModel.connect()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text("Initiating fight with \(friend.username)")
                        .font(.title)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Fight Initiation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//
//  ishApp.swift
//  ish
//
//  Created by Spencer Mitton on 4/30/25.
//

import SwiftUI
import WebRTC

struct MainView: View {
    let signalClient: SignalingClient
    let webRTCClient: WebRTCClient
    @State private var fightCode: String = ""
    @StateObject private var supabaseService = SupabaseService()
    @State private var friends: [Friend] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Stats section (top third)
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: UIScreen.main.bounds.height / 3)
                .overlay(
                    VStack {
                        Text("Stats")
                            .font(.title)
                            .padding()
                        // Placeholder for future stats
                        Text("Wins: 0")
                        Text("Streak: 0")
                    }
                )

            // Friends list section
            List {
                Section(header: Text("Friends")) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if friends.isEmpty {
                        Text("No friends yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(friends) { friend in
                            Text(friend.username)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationBarItems(
            trailing: Button("Generate Fight Code") {
                generateFightCode()
            }
        )
        .task {
            await fetchFriends()
        }
    }

    func generateFightCode() {
        fightCode = UUID().uuidString
    }

    private func fetchFriends() async {
        isLoading = true
        errorMessage = nil

        do {
            friends = try await supabaseService.getFriends()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

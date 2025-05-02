import SwiftUI

struct UsernameSetupView: View {
    @StateObject private var supabaseService = SupabaseService()
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showMainView = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a username")
                .font(.title)
                .padding(.top, 50)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: {
                Task {
                    await setUsername()
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || isLoading)

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $showMainView) {
            MainView(
                signalClient: buildSignalingClient(),
                webRTCClient: WebRTCClient(iceServers: Config.default.webRTCIceServers)
            )
        }
    }

    private func setUsername() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabaseService.updateUsername(username)
            showMainView = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildSignalingClient() -> SignalingClient {
        let webSocketProvider: WebSocketProvider
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocket(url: Config.default.signalingServerUrl)
        } else {
            webSocketProvider = StarscreamWebSocket(url: Config.default.signalingServerUrl)
        }
        return SignalingClient(webSocket: webSocketProvider)
    }
}

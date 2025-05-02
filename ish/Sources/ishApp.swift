//
//  ishApp.swift
//  ish
//
//  Created by Spencer Mitton on 4/30/25.
//

import AVFoundation
import Foundation
import SwiftUI
import UserNotifications
import WebRTC

@main
struct ishApp: App {
    private let config = Config.default
    @StateObject private var supabaseService = SupabaseService()
    @State private var isAuthenticated = false

    init() {
        requestPermissionsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if isAuthenticated {
                    MainView(
                        signalClient: buildSignalingClient(),
                        webRTCClient: WebRTCClient(iceServers: config.webRTCIceServers)
                    )
                    .navigationTitle("Ish")
                    .navigationBarTitleDisplayMode(.large)
                } else {
                    PhoneSignInView()
                }
            }
            .task {
                // Check if user is already authenticated
                let service = supabaseService
                if (try? await service.hasSession()) == true {
                    isAuthenticated = true
                }
            }
        }
    }

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in

        }
    }

    private func buildSignalingClient() -> SignalingClient {
        let webSocketProvider: WebSocketProvider
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocket(url: config.signalingServerUrl)
        } else {
            webSocketProvider = StarscreamWebSocket(url: config.signalingServerUrl)
        }
        return SignalingClient(webSocket: webSocketProvider)
    }

    private func requestPermissionsIfNeeded() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("Camera permission: \(granted)")
            }
        }

        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print("Microphone permission: \(granted)")
            }
        }
    }
}

#if canImport(HotSwiftUI)
    @_exported import HotSwiftUI
#elseif canImport(Inject)
    @_exported import Inject
#endif

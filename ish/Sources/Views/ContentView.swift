//
//  ContentView.swift
//  ish
//
//  Created by Spencer Mitton on 4/30/25.
//

import SwiftUI
import WebRTC

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ContentView()
}

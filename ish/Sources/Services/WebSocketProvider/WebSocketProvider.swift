//
//  ishApp.swift
//  ish
//
//  Created by Spencer Mitton on 4/30/25.
//

import Foundation

protocol WebSocketProviderDelegate: AnyObject {
    func webSocketDidConnect(_ webSocket: WebSocketProvider)
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider)
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data)
}

protocol WebSocketProvider: AnyObject {
    var delegate: WebSocketProviderDelegate? { get set }
    func connect()
    func send(data: Data)
}

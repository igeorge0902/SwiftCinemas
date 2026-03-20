//
//  Websocket.swift
//  SwiftCinemas
//
//  Created by Gaspar Gyorgy on 2025. 03. 08..
//  Copyright © 2025. George Gaspar. All rights reserved.
//

import Foundation

class WebSocketManager: NSObject {
    var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: DispatchSourceTimer?

    func connect() {
        let url = URL(string: URLManager.webSocketURL)!
        lazy var session: URLSession = .sharedCustomSession
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
        startPing()
    }

    func disconnect() {
        stopPing()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
                self.reconnectWebSocket()
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received: \(text)")
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    fatalError()
                }
                self.receiveMessage() // Keep listening
            }
        }
    }

    // MARK: - Keepalive ping

    private func startPing() {
        stopPing()
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now() + 30, repeating: 30)
        timer.setEventHandler { [weak self] in
            self?.sendPing()
        }
        timer.resume()
        pingTimer = timer
    }

    private func stopPing() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("WebSocket ping failed: \(error.localizedDescription)")
                self?.reconnectWebSocket()
            }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed: \(closeCode)")
        reconnectWebSocket()
    }
    
    func reconnectWebSocket() {
        stopPing()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
            print("Reconnecting WebSocket...")
            self?.connect()
        }
    }
}

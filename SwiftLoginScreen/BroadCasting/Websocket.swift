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

    func connect() {
        let url = URL(string: "wss://milo.crabdance.com/mbook-1/ws")!
       // let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        lazy var session: URLSession = .sharedCustomSession
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }

    func receiveMessage() {
        webSocketTask?.receive { result in
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
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed: \(closeCode)")
        reconnectWebSocket() // Reconnect on unexpected closure
    }
    
    func reconnectWebSocket() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { // Wait 3 sec before reconnecting
            print("Reconnecting WebSocket...")
            self.connect()
        }
    }
}

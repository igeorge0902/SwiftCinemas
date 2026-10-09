// Websocket.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation

@MainActor
final class WebSocketManager: NSObject {
    // MARK: Internal

    var webSocketTask: URLSessionWebSocketTask?

    func connect() {
        isStopped = false
        cancelPendingReconnect()
        retireCurrentTask()

        var components = URLComponents(string: URLManager.webSocketURL)!
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "deviceId" }
        queryItems.append(URLQueryItem(name: "deviceId", value: currentDeviceId()))
        components.queryItems = queryItems
        let url = components.url!
        let session: URLSession = .sharedCustomSession
        let task = session.webSocketTask(with: url)
        connectionGeneration &+= 1
        let generation = connectionGeneration
        task.taskDescription = String(generation)
        webSocketTask = task
        task.resume()
        receiveMessage(on: task, generation: generation)
        startPing(generation: generation)
    }

    func disconnect() {
        isStopped = true
        cancelPendingReconnect()
        retireCurrentTask()
    }

    func receiveMessage() {
        guard let task = webSocketTask else { return }
        receiveMessage(on: task, generation: connectionGeneration)
    }

    // MARK: Private

    private var pingTimer: DispatchSourceTimer?
    private var reconnectTask: Task<Void, Never>?
    private var connectionGeneration: UInt64 = 0
    private var isStopped = false

    private enum ReceiveEvent: Sendable {
        case text(String)
        case binary(Data)
        case failure(String)
    }

    /// Decode only the additive metadata; the original payload and presentation stay unchanged.
    private struct ScreenNewsMetadata: Decodable {
        let eventType: String
        let category: String

        private enum CodingKeys: String, CodingKey {
            case eventType, category
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            eventType = try values.decodeIfPresent(String.self, forKey: .eventType) ?? "created"
            category = try values.decodeIfPresent(String.self, forKey: .category) ?? "screening"
        }
    }

    private func decodeScreenNewsMetadata(from data: Data) {
        do {
            let metadata = try JSONDecoder().decode(ScreenNewsMetadata.self, from: data)
            print("WebSocket metadata: \(metadata.category), \(metadata.eventType)")
        } catch {
            // Non-screen messages and non-JSON binary frames still use the legacy logging above.
            print("WebSocket metadata not decoded: \(error.localizedDescription)")
        }
    }

    private func receiveMessage(on task: URLSessionWebSocketTask, generation: UInt64) {
        task.receive { @Sendable [weak self] result in
            let event: ReceiveEvent
            switch result {
            case let .failure(error):
                event = .failure(error.localizedDescription)
            case let .success(message):
                switch message {
                case let .string(text):
                    event = .text(text)
                case let .data(data):
                    event = .binary(data)
                @unknown default:
                    fatalError()
                }
            }
            Task { @MainActor [weak self] in
                self?.handleReceive(event, generation: generation)
            }
        }
    }

    private func handleReceive(_ event: ReceiveEvent, generation: UInt64) {
        guard !isStopped, generation == connectionGeneration, let task = webSocketTask else { return }
        switch event {
        case let .failure(description):
            print("WebSocket error: \(description)")
            scheduleReconnect(from: generation)
        case let .text(text):
            print("Received: \(text)")
            decodeScreenNewsMetadata(from: Data(text.utf8))
            receiveMessage(on: task, generation: generation)
        case let .binary(data):
            print("Received binary data: \(data)")
            decodeScreenNewsMetadata(from: data)
            receiveMessage(on: task, generation: generation)
        }
    }

    private func scheduleReconnect(from generation: UInt64) {
        guard !isStopped, generation == connectionGeneration, reconnectTask == nil else { return }
        retireCurrentTask()
        reconnectTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                return
            }
            guard let self = self, !Task.isCancelled else { return }
            self.reconnectTask = nil
            guard !self.isStopped else { return }
            print("Reconnecting WebSocket...")
            self.connect()
        }
    }

    private func cancelPendingReconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func retireCurrentTask() {
        stopPing()
        connectionGeneration &+= 1
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // MARK: - Keepalive ping

    private func startPing(generation: UInt64) {
        stopPing()
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now() + 30, repeating: 30)
        timer.setEventHandler { @Sendable [weak self] in
            Task { @MainActor [weak self] in
                self?.sendPing(generation: generation)
            }
        }
        timer.resume()
        pingTimer = timer
    }

    private func stopPing() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    private func sendPing(generation: UInt64) {
        guard !isStopped, generation == connectionGeneration, let task = webSocketTask else { return }
        task.sendPing { @Sendable [weak self] error in
            guard let error = error else { return }
            let description = error.localizedDescription
            Task { @MainActor [weak self] in
                print("WebSocket ping failed: \(description)")
                self?.scheduleReconnect(from: generation)
            }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_: URLSession, webSocketTask closedTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        print("WebSocket closed: \(closeCode)")
        guard let description = closedTask.taskDescription,
              let generation = UInt64(description) else { return }
        Task { @MainActor [weak self] in
            self?.scheduleReconnect(from: generation)
        }
    }

    func reconnectWebSocket() {
        scheduleReconnect(from: connectionGeneration)
    }
}

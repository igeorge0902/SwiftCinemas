// ErrorHandler.swift
// Created by Gyorgy Gaspar on 2026.05.23.

enum ErrorHandler {
    static func message(for error: AppError) -> String {
        switch error {
        case .networkFailure:
            return "No internet connection"

        case .authRequired:
            return "Session expired"

        case .activationRequired:
            return "Activation required"

        case let .httpError(_, message):
            return message.isEmpty ? "Server error" : message

        case .decodingFailed:
            return "Invalid data received"
        }
    }
}

//
//  ErrorHandler.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 03. 28..
//  Copyright © 2026 George Gaspar. All rights reserved.
//

final class ErrorHandler {

    static func message(for error: AppError) -> String {
        switch error {
        case .networkFailure:
            return "No internet connection"

        case .authRequired:
            return "Session expired"

        case .activationRequired:
            return "Activation required"

        case .httpError(_, let message):
            return message.isEmpty ? "Server error" : message

        case .decodingFailed:
            return "Invalid data received"
        }
    }
}

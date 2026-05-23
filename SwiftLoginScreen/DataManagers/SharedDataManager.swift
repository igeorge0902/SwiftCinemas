// SharedDataManager.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation

/// Common contract for singleton-style data managers used by migrated ViewControllers.
///
/// Conformers provide a short domain tag (for log prefixing) and use
/// ``handleError(_:)`` to normalize logging while preserving the original error.
@MainActor
protocol SharedDataManager: AnyObject {
    /// Human-readable manager name used as log domain (for example: `Movies`, `Auth`).
    static var domain: String { get }

    /// Logs an error with the manager domain and returns the same error so callers can rethrow.
    ///
    /// - Parameter error: The error raised by networking/parsing/business logic.
    /// - Returns: The exact same error instance, after standardized logging.
    func handleError(_ error: Error) -> Error
}

@MainActor
extension SharedDataManager {
    func handleError(_ error: Error) -> Error {
        if let appError = error as? AppError {
            NSLog("[%@] %@", Self.domain, appError.localizedDescription)
        } else {
            NSLog("[%@] %@", Self.domain, error.localizedDescription)
        }
        return error
    }
}

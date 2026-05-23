// AppError.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation

enum AppError: Error {
    case networkFailure(underlying: Error)
    case httpError(statusCode: Int, message: String)
    case authRequired
    case activationRequired(voucherActive: Bool)
    case decodingFailed
}

extension AppError {
    var userMessage: String {
        switch self {
        case let .networkFailure(underlying):
            guard let urlError = underlying as? URLError else {
                return "Network request failed. Please try again."
            }
            switch urlError.code {
            case .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost:
                return "Cannot reach the server right now. Check internet/proxy settings and try again."
            case .notConnectedToInternet:
                return "No internet connection. Please reconnect and try again."
            case .timedOut:
                return "Request timed out. Please try again."
            default:
                return "Network request failed (\(urlError.code.rawValue)). Please try again."
            }
        case let .httpError(statusCode, _):
            return "Server returned an error (\(statusCode)). Please try again."
        case .authRequired:
            return "Your session expired. Please sign in again."
        case .activationRequired:
            return "Activation is required for this account."
        case .decodingFailed:
            return "Received unexpected data from server. Please try again."
        }
    }
}

extension Error {
    var userMessage: String {
        if let appError = self as? AppError {
            return appError.userMessage
        }
        return localizedDescription
    }
}

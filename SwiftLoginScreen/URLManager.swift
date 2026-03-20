//
//  URLManager.swift
//  SwiftCinemas
//
//  Created by George Gaspar on 2026. 03. 20.
//  Copyright © 2026. George Gaspar. All rights reserved.
//

import Foundation

/// Centralised URL configuration for all backend services.
/// Change `baseHost` to point the app at a different environment.
enum URLManager {

    // MARK: - Base host (single place to change)

    static let baseHost = "milo.crabdance.com"
    static let baseURL  = "https://\(baseHost)"

    // MARK: - Service root paths

    static let loginPath  = "/login"
    static let mbooksPath = "/mbooks-1/rest/book"
    static let imagePath  = "/simple-service-webapp/webapi/myresource"

    // MARK: - WebSocket

    static let webSocketURL = "wss://\(baseHost)/mbook-1/ws"

    // MARK: - Convenience builders

    /// Full URL for the login/auth gateway.  e.g. `URLManager.login("/HelloWorld")`
    static func login(_ path: String) -> String {
        return baseURL + loginPath + path
    }

    /// Full URL for the movie/booking API.  e.g. `URLManager.mbooks("/movies/paging")`
    static func mbooks(_ path: String) -> String {
        return baseURL + mbooksPath + path
    }

    /// Full URL for an image resource.  e.g. `URLManager.image("/movies/poster.jpg")`
    static func image(_ path: String) -> String {
        return baseURL + imagePath + path
    }
}


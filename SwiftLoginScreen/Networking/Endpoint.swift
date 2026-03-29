//
//  Endpoint.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 03. 28..
//  Copyright © 2026 George Gaspar. All rights reserved.
//

import Foundation

struct Endpoint {
    let path: String
    let method: String
    let query: [URLQueryItem]?
    let body: Data?
    /// When set, ``APIClient`` may read/write ``ResponseCache`` for successful GET responses.
    let cacheKey: String?
    /// When set, the request URL is this (optionally merged with ``query``) instead of ``baseURL`` + ``path``.
    let absoluteURL: URL?

    init(
        path: String = "",
        method: String,
        query: [URLQueryItem]? = nil,
        body: Data? = nil,
        cacheKey: String? = nil,
        absoluteURL: URL? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.body = body
        self.cacheKey = cacheKey
        self.absoluteURL = absoluteURL
    }

    func buildRequest(baseURL: URL, headers: [String: String]) -> URLRequest {
        let resolvedURL: URL
        if let absoluteURL {
            var components = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false)!
            if let query, !query.isEmpty {
                var merged = components.queryItems ?? []
                merged.append(contentsOf: query)
                components.queryItems = merged
            }
            resolvedURL = components.url!
        } else {
            var url = baseURL
            let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            for segment in trimmed.split(separator: "/") {
                url = url.appendingPathComponent(String(segment))
            }

            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = query
            resolvedURL = components.url!
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = method
        request.httpBody = body

        headers.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        return request
    }
}

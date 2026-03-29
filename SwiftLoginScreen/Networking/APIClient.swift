//
//  APIClient.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 03. 28..
//  Copyright © 2026 George Gaspar. All rights reserved.
//

import UIKit

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestData(_ endpoint: Endpoint) async throws -> Data
    func requestData(_ endpoint: Endpoint, headers: HeaderProvider) async throws -> Data
}

/// View controllers that receive the shared ``APIClient`` from ``AppDelegate``.
protocol HasAPIClient: AnyObject {
    var apiClient: APIClient! { get set }
}

extension HasAPIClient where Self: UIViewController {
    /// Resolves the app-wide client from ``AppDelegate/services`` (call from `viewDidLoad` before using ``apiClient``).
    func injectAPIClientIfNeeded() {
        guard apiClient == nil else { return }
        apiClient = (UIApplication.shared.delegate as? AppDelegate)?.services.apiClient
    }
}

final class APIClient: APIClientProtocol {

    //private let session: URLSession
    private var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 20

        let delegate = CustomURLSessionDelegate(
            allowedHosts: [
                URLManager.baseHost,
                "localhost",
                "igeorge1982.local"
            ]
        )

        return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }()
    
    private let cache: ResponseCache
    private let headers: HeaderProvider
    private let baseURL: URL

    init(
        baseURL: URL,
        session: URLSession = .sharedCustomSession,
        cache: ResponseCache = RealmResponseCache(),
        headers: HeaderProvider = SessionHeaderProvider()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
        self.headers = headers
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        try await requestData(endpoint, headers: headers)
    }

    func requestData(_ endpoint: Endpoint, headers headerProvider: HeaderProvider) async throws -> Data {
        if let key = endpoint.cacheKey, endpoint.method.uppercased() == "GET" {
            let cached = await MainActor.run {
                self.cache.cachedResponse(for: key)
            }
            if let cached {
                return cached
            }
        }

        let request = endpoint.buildRequest(baseURL: baseURL, headers: headerProvider.headers())

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AppError.networkFailure(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkFailure(underlying: URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200...299:
            if let key = endpoint.cacheKey, endpoint.method.uppercased() == "GET" {
                await MainActor.run {
                    self.cache.save(data, for: key)
                }
            }
            return data

        case 401:
            throw AppError.authRequired

        case 300:
            throw AppError.activationRequired(voucherActive: false)

        default:
            throw AppError.httpError(
                statusCode: http.statusCode,
                message: String(data: data, encoding: .utf8) ?? ""
            )
        }
    }
}

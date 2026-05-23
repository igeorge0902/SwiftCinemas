// CustomURLSessionDelegate.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation

final class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
    // MARK: Lifecycle

    init(allowedHosts: Set<String>) {
        self.allowedHosts = allowedHosts
    }

    // MARK: Internal

    // MARK: - SSL / Certificate Handling

    func urlSession(
        _: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        if allowedHosts.contains(host) {
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: Private

    private let allowedHosts: Set<String>
}

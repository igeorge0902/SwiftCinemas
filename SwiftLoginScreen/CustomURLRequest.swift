//
//  CustomURLRequest.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/11/15.
//

import Foundation

extension URLRequest {
    /// Helper for making a URL request.
    /// JSON encodes parameters if any are provided. You may want to change this if your server uses, say, XML.

    static func requestWithURL(_ URL: Foundation.URL, method: String, queryParameters: [String: String]?, bodyParameters: NSDictionary?, headers: [String: String]?, cachePolicy _: NSURLRequest.CachePolicy?, timeoutInterval _: TimeInterval?, isCacheable _: String?, contentType: String?, bodyToPost: Data?) -> URLRequest {
        // If there's a querystring, append it to the URL.
        let actualURL: Foundation.URL

        if let queryParameters {
            var components = URLComponents(url: URL, resolvingAgainstBaseURL: true)!
            components.queryItems = queryParameters.map { key, value in URLQueryItem(name: key, value: value) }

            actualURL = components.url!

        } else {
            actualURL = URL
        }

        // Make the request for the given method.
        let request = NSMutableURLRequest(url: actualURL)
        request.httpMethod = method

        // Add any body JSON params (for POSTs).
        if contentType == contentType_.json.rawValue {
            if let bodyParameters {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: [])
            }
        }

        if contentType == contentType_.urlEncoded.rawValue {
            if let bodyToPost {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyToPost
            }
        }

        if contentType == contentType_.image.rawValue {
            request.setValue("image/jpeg", forHTTPHeaderField: "Accept")
        }

        // Add any extra headers if given.
        if let headers {
            for (field, value) in headers {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }

        // TEST
        request.httpShouldHandleCookies = true
        return request as URLRequest
    }
}

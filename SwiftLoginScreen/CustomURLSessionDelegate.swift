//
//  CustomURLSessionDelegate.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/11/15.
//

import Foundation
import UIKit

class CustomURLSessionDelegate: URLSessionDownloadTask, URLSessionDelegate {
    // MARK: - NSURLSessionDelegate

    func urlSession(_: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // For example, you may want to override this to accept some self-signed certs here.
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           Constants.selfSignedHosts.contains(challenge.protectionSpace.host)
        {
            // Allow the self-signed cert.
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            // You *have* to call completionHandler either way, so call it to do the default action.
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func URLSession(_: Foundation.URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingToURL _: URL) {
        //  if let data = try? Data(contentsOf: location) {
        // work with data ...
        // UIImage(data: data)
        //  }
    }

    enum Constants {
        // A list of hosts you allow self-signed certificates on.
        // You'd likely have your dev/test servers here.
        // Please don't put your production server here!

        static let selfSignedHosts: Set<String> = ["milo.crabdance.com", "localhost", "igeorge1982.local"]
    }

    func URLSession(_: Foundation.URLSession, task _: URLSessionTask, willPerformHTTPRedirection _: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void)
    {
        let newRequest: URLRequest? = request

        print(newRequest?.description as Any)
        completionHandler(newRequest)
    }
}

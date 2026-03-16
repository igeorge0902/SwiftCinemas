//
//  Responses.swift
//  SwiftLoginScreen
//
//  Created by Gaspar Gyorgy on 18/11/15.
//

import Foundation

/// This wraps up all the response from a URL request together,
/// so it'll be easy for you to add any helpers/fields as you need it.

struct Responses {
    // Actual fields.
    let data: Data!
    let response: URLResponse!
    var error: NSError?

    // Helpers.
    var HTTPResponse: HTTPURLResponse! {
        response as? HTTPURLResponse
    }

    var responseJSON: AnyObject? {
        if let data {
            try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject?
        } else {
            nil
        }
    }

    var responseString: String? {
        if let data,
           let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        {
            String(string)
        } else {
            nil
        }
    }
}

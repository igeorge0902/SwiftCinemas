//
//  HeaderProvider.swift
//  SwiftCinemas
//
//  Created by GYORGY GASPAR on 2026. 03. 28..
//  Copyright © 2026 George Gaspar. All rights reserved.
//

import UIKit

protocol HeaderProvider {
    func headers() -> [String: String]
}

/// Same session headers as ``GeneralRequestManager.dataTask`` for `https://…` hosts (`Ciphertext`, `X-Token`, `X-Device`).
final class SessionHeaderProvider: HeaderProvider {
    func headers() -> [String: String] {
        let xtoken = UserDefaults.standard.value(forKey: "X-Token") as? String ?? ""
        return [
            "Ciphertext": xtoken,
            "X-Token": "client-secret",
            "X-Device": UIDevice.current.identifierForVendor!.uuidString
        ]
    }
}

struct MergedHeaderProvider: HeaderProvider {
    let base: HeaderProvider
    let extra: [String: String]

    func headers() -> [String: String] {
        var h = base.headers()
        for (k, v) in extra { h[k] = v }
        return h
    }
}

/// Image/binary GETs used `headers: nil` in ``GeneralRequestManager`` — no ciphertext.
struct MinimalGETHeaderProvider: HeaderProvider {
    func headers() -> [String: String] { [:] }
}

struct RapidMovieDatabaseHeaderProvider: HeaderProvider {
    func headers() -> [String: String] {
        [
            "RapidAPI Project": "default-application_4096793",
            "x-rapidapi-host": "movie-database-imdb-alternative.p.rapidapi.com",
            "x-rapidapi-key": "60b13d7e5bmshfdf31342761c35cp1c3a50jsn0fd6be87de26"
        ]
    }
}

/// Headers for `POST /login/HelloWorld` (HMAC-SHA512). Matches the legacy manual `URLRequest` login flow.
struct HMACLoginHeaderProvider: HeaderProvider {
    let contentLength: String
    let hmacHash: String
    let microTime: String

    func headers() -> [String: String] {
        [
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "Content-Length": contentLength,
            "X-HMAC-HASH": hmacHash,
            "X-MICRO-TIME": microTime
        ]
    }
}

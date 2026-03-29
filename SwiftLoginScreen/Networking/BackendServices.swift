//
//  BackendServices.swift
//  SwiftCinemas
//
//  Named after backend areas: mbooks REST, login gateway (dalogin), image webapp, RapidAPI IMDb.
//

import Foundation
import UIKit

// MARK: - App container

struct AppServices {
    let apiClient: APIClient
    let mbooks: MbooksService
    let loginGateway: LoginGatewayService
    let images: ImageResourceService
    let rapidMovieDatabase: RapidMovieDatabaseService
}

protocol HasAppServices: AnyObject {
    var appServices: AppServices! { get set }
}

extension HasAppServices where Self: UIViewController {
    func injectAppServicesIfNeeded() {
        guard appServices == nil else { return }
        appServices = (UIApplication.shared.delegate as? AppDelegate)?.services
    }
}

// MARK: - mbooks-1/rest/book (MbooksService)

@MainActor
final class MbooksService {
    private let apiClient: APIClient
    private let session = SessionHeaderProvider()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    private static let bookRoot = "mbooks-1/rest/book"

    /// Full URL string including query — matches legacy Realm `CachedResponse.url` keys.
    static func mbooksURLString(suffix: String, query: [String: String]?) -> String {
        let normalized = suffix.hasPrefix("/") ? suffix : "/" + suffix
        var c = URLComponents(string: URLManager.mbooks(normalized))!
        if let q = query, !q.isEmpty {
            c.queryItems = q.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return c.url!.absoluteString
    }

    private func get(suffix: String, query: [String: String]?, realmCache: Bool) async throws -> Data {
        let p = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        let fullPath = "\(Self.bookRoot)/\(p)"
        let items = query?.map { URLQueryItem(name: $0.key, value: $0.value) }
        let cacheKey = realmCache ? Self.mbooksURLString(suffix: "/" + p, query: query) : nil
        let endpoint = Endpoint(path: fullPath, method: "GET", query: items, body: nil, cacheKey: cacheKey, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: session)
    }

    private func postJSON(suffix: String, body: [String: Any]) async throws -> Data {
        let p = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        let fullPath = "\(Self.bookRoot)/\(p)"
        let data = try JSONSerialization.data(withJSONObject: body, options: [])
        let hp = MergedHeaderProvider(base: session, extra: ["Content-Type": "application/json"])
        let endpoint = Endpoint(path: fullPath, method: "POST", query: nil, body: data, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }

    private func deleteJSON(suffix: String, body: [String: Any]) async throws -> Data {
        let p = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        let fullPath = "\(Self.bookRoot)/\(p)"
        let data = try JSONSerialization.data(withJSONObject: body, options: [])
        let hp = MergedHeaderProvider(base: session, extra: ["Content-Type": "application/json"])
        let endpoint = Endpoint(path: fullPath, method: "DELETE", query: nil, body: data, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }

    /// GET with `Content-Type: application/json` (legacy ``GeneralRequestManager`` behaviour for admin movie pickers).
    private func getExpectingJSONBodyHeader(suffix: String, query: [String: String]?, realmCache: Bool) async throws -> Data {
        let p = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        let fullPath = "\(Self.bookRoot)/\(p)"
        let items = query?.map { URLQueryItem(name: $0.key, value: $0.value) }
        let cacheKey = realmCache ? Self.mbooksURLString(suffix: "/" + p, query: query) : nil
        let hp = MergedHeaderProvider(base: session, extra: ["Content-Type": "application/json"])
        let endpoint = Endpoint(path: fullPath, method: "GET", query: items, body: nil, cacheKey: cacheKey, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }

    func moviesPaging(query: [String: String]) async throws -> Data {
        try await get(suffix: "movies/paging", query: query, realmCache: true)
    }

    func moviesSearch(query: [String: String]) async throws -> Data {
        try await get(suffix: "movies/search", query: query, realmCache: false)
    }

    func adminMoviesOnVenuesCategorized(query: [String: String]?) async throws -> Data {
        try await get(suffix: "admin/moviesonvenuescategorized", query: query, realmCache: true)
    }

    func adminMoviesOnVenuesSearch(query: [String: String]) async throws -> Data {
        try await get(suffix: "admin/moviesonvenuessearch", query: query, realmCache: true)
    }

    func adminMoviesOnVenues() async throws -> Data {
        try await getExpectingJSONBodyHeader(suffix: "admin/moviesonvenues", query: nil, realmCache: false)
    }

    func venue(movieId: String) async throws -> Data {
        try await get(suffix: "venue/\(movieId)", query: nil, realmCache: true)
    }

    func locations() async throws -> Data {
        try await get(suffix: "locations", query: nil, realmCache: false)
    }

    func locationsVenue(venuesId: String) async throws -> Data {
        try await get(suffix: "locations/venue", query: ["venuesId": venuesId], realmCache: false)
    }

    func venueMovies(locationId: String) async throws -> Data {
        try await get(suffix: "venue/movies", query: ["locationId": locationId], realmCache: false)
    }

    func dates(locationId: String, movieId: String) async throws -> Data {
        try await get(suffix: "dates/\(locationId)/\(movieId)", query: nil, realmCache: false)
    }

    func dates(screenId: String) async throws -> Data {
        try await get(suffix: "dates/\(screenId)", query: nil, realmCache: false)
    }

    func seats(screeningDateId: String) async throws -> Data {
        try await get(suffix: "seats/\(screeningDateId)", query: nil, realmCache: false)
    }

    func adminAddScreen(body: [String: Any]) async throws -> Data {
        try await postJSON(suffix: "admin/addscreen", body: body)
    }

    func adminUpdateScreen(body: [String: Any]) async throws -> Data {
        try await postJSON(suffix: "admin/updatescreen", body: body)
    }

    func adminDeleteScreen(body: [String: Any]) async throws -> Data {
        try await deleteJSON(suffix: "admin/deletescreen", body: body)
    }
}

// MARK: - /login (LoginGatewayService)

@MainActor
final class LoginGatewayService {
    private let apiClient: APIClient
    private let session = SessionHeaderProvider()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    private func loginPath(_ suffix: String) -> String {
        let s = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        return "login/\(s)"
    }

    func signIn(
        username: String,
        passwordHash: String,
        deviceId: String,
        systemVersion: String
    ) async throws {
        let post = "user=\(username)&pswrd=\(passwordHash)&deviceId=\(deviceId)&ios=\(systemVersion)" as NSString
        let postData = post.data(using: String.Encoding.ascii.rawValue)!

        let time = zeroTime(0).getCurrentMillis()
        let post_ = "/login/HelloWorld:user=\(username)&pswrd=\(passwordHash)&deviceId=\(deviceId):\(time):\(post.length)"

        let hmacSHA512 = CryptoJS.hmacSHA512()
        let hmacSec = hmacSHA512.hmac(username, secret: passwordHash) as NSString
        let hmacHash = hmacSHA512.hmac(post_, secret: hmacSec as String) as NSString

        NSLog("hmacSecret: %@", hmacSec)
        NSLog("PostData: %@", post)

        let endpoint = Endpoint(
            path: loginPath("HelloWorld"),
            method: "POST",
            body: postData,
            cacheKey: nil,
            absoluteURL: nil
        )

        let headerProvider = HMACLoginHeaderProvider(
            contentLength: String(postData.count),
            hmacHash: hmacHash as String,
            microTime: String(time)
        )

        let data = try await apiClient.requestData(endpoint, headers: headerProvider)

        guard !data.isEmpty else {
            throw AppError.decodingFailed
        }

        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                print("Cookie_ name: \(cookie.name), Cookie_ value: \(cookie.value)")
            }
        }

        do {
            let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
            let success = jsonData.value(forKey: "success") as! NSInteger
            let sessionID = jsonData.value(forKey: "JSESSIONID") as! NSString
            let xtoken = jsonData.value(forKey: "X-Token") as! NSString

            NSLog("sessionId ==> %@", sessionID)
            NSLog("Success: %ld", success)

            if success == 1 {
                NSLog("Login SUCCESS")
                let prefs = UserDefaults.standard
                prefs.set(username, forKey: "USERNAME")
                prefs.set(1, forKey: "ISLOGGEDIN")
                prefs.set(0, forKey: "ISWEBLOGGEDIN")
                prefs.setValue(sessionID, forKey: "JSESSIONID")
                prefs.setValue(deviceId, forKey: "deviceId")
                prefs.setValue(xtoken, forKey: "X-Token")
                prefs.synchronize()
            }

            NSLog("got a 200")
        } catch {
            NSLog("JSON parsing error")
            throw AppError.decodingFailed
        }
    }

    func getUser() async throws -> Data {
        let endpoint = Endpoint(path: loginPath("admin"), method: "GET", query: nil, body: nil, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: session)
    }
    
    func getCheckOut() async throws -> Data {
        let endpoint = Endpoint(path: loginPath("CheckOut"), method: "GET", query: nil, body: nil, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: session)
    }

    func postCheckOut(body: Data) async throws -> Data {
        let hp = MergedHeaderProvider(base: session, extra: [
            "Content-Type": "application/x-www-form-urlencoded",
            "Content-Length": "\(body.count)"
        ])
        let endpoint = Endpoint(path: loginPath("CheckOut"), method: "POST", query: nil, body: body, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }

    func getAllPurchases() async throws -> Data {
        let endpoint = Endpoint(
            path: loginPath("GetAllPurchases"),
            method: "GET",
            query: [URLQueryItem(name: "book", value: "GetAllPurchases")],
            body: nil,
            cacheKey: nil,
            absoluteURL: nil
        )
        return try await apiClient.requestData(endpoint, headers: session)
    }

    func getManagePurchases(purchaseId: String) async throws -> Data {
        let endpoint = Endpoint(
            path: loginPath("ManagePurchases"),
            method: "GET",
            query: [URLQueryItem(name: "purchaseId", value: purchaseId)],
            body: nil,
            cacheKey: nil,
            absoluteURL: nil
        )
        return try await apiClient.requestData(endpoint, headers: session)
    }

    func postManagePurchases(body: Data) async throws -> Data {
        let hp = MergedHeaderProvider(base: session, extra: [
            "Content-Type": "application/x-www-form-urlencoded",
            "Content-Length": "\(body.count)"
        ])
        let endpoint = Endpoint(path: loginPath("ManagePurchases"), method: "POST", query: nil, body: body, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }

    func postActivation(deviceId: String, user: String) async throws -> Data {
  
        let json: [String: Any] = [
            "deviceId": deviceId,
            "user": user
        ]

        let body = try JSONSerialization.data(withJSONObject: json, options: [])

        let hp = MergedHeaderProvider(
            base: session,
            extra: [
                "Content-Type": "application/json"
            ]
        )
        
        let endpoint = Endpoint(path: loginPath("activation"), method: "POST", query: nil, body: body, cacheKey: nil, absoluteURL: nil)
        return try await apiClient.requestData(endpoint, headers: hp)
    }
}

// MARK: - simple-service-webapp images (ImageResourceService)

@MainActor
final class ImageResourceService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getData(urlString: String, realmCache: Bool) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AppError.decodingFailed
        }
        let key = realmCache ? urlString : nil
        let endpoint = Endpoint(path: "", method: "GET", query: nil, body: nil, cacheKey: key, absoluteURL: url)
        return try await apiClient.requestData(endpoint, headers: MinimalGETHeaderProvider())
    }
}

// MARK: - RapidAPI IMDb (RapidMovieDatabaseService)

@MainActor
final class RapidMovieDatabaseService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func imdbTitle(imdbId: String, realmCache: Bool) async throws -> Data {
        var c = URLComponents(string: "https://movie-database-imdb-alternative.p.rapidapi.com")!
        c.queryItems = [URLQueryItem(name: "i", value: imdbId)]
        guard let url = c.url else { throw AppError.decodingFailed }
        let key = realmCache ? url.absoluteString : nil
        let endpoint = Endpoint(path: "", method: "GET", query: nil, body: nil, cacheKey: key, absoluteURL: url)
        return try await apiClient.requestData(endpoint, headers: RapidMovieDatabaseHeaderProvider())
    }
}

//
//  AuthDataManager.swift
//  SwiftCinemas
//

import Foundation
import UIKit

final class AuthDataManager: SharedDataManager, HasAppServices {
    static let shared = AuthDataManager()
    static var domain: String { "Auth" }

    var appServices: AppServices!

    private var apiClient: APIClient { appServices.apiClient }
    private var loginGateway: LoginGatewayService { appServices.loginGateway }
    private let session: URLSession = .sharedCustomSession

    private init() {}

    /// Sign in with username and password
    /// - Note: Throws AppError on failure; stores session automatically
    func signIn(
        username: String,
        passwordHash: String,
        deviceId: String,
        systemVersion: String
    ) async throws {
        do {
            try await loginGateway.signIn(
                username: username,
                passwordHash: passwordHash,
                deviceId: deviceId,
                systemVersion: systemVersion
            )
        } catch {
            throw handleError(error)
        }
    }

    /// Fetch current user profile
    func fetchUser() async throws -> [String: Any] {
        do {
            let data = try await loginGateway.getUser()
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            return json
        } catch {
            throw handleError(error)
        }
    }

    /// Activate device with voucher
    func activate(deviceId: String, user: String) async throws {
        do {
            let data = try await loginGateway.postActivation(deviceId: deviceId, user: user)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

            if let success = json["success"] as? NSNumber, success.intValue == 1 {
                NSLog("[%@] Activation successful", Self.domain)
            } else {
                throw AppError.decodingFailed
            }
        } catch {
            throw handleError(error)
        }
    }

    func fetchUserProfile() async throws -> UserProfileModel {
        let user = try await fetchUser()
        return UserProfileModel(
            username: user["user"] as? String ?? "",
            email: user["email"] as? String ?? "",
            profilePicture: user["profilePicture"] as? String ?? ""
        )
    }

    func activateCurrentDevice(user: String) async throws {
        try await activate(deviceId: deviceId, user: user)
    }

    /// Refresh in-memory/auth context from persisted session state and validate with backend.
    func refreshToken() async throws -> SessionTokenModel {
        let token = SecureStore.get("X-Token")
            ?? (UserDefaults.standard.value(forKey: "X-Token") as? String)
            ?? ""
        let sessionId = SecureStore.get("JSESSIONID")
            ?? (UserDefaults.standard.value(forKey: "JSESSIONID") as? String)
            ?? ""
        let storedDeviceId = UserDefaults.standard.value(forKey: "deviceId") as? String ?? ""

        guard !token.isEmpty, !sessionId.isEmpty else {
            throw AppError.authRequired
        }

        // Force a lightweight authenticated call so stale sessions surface as authRequired.
        _ = try await fetchUser()

        return SessionTokenModel(
            token: token,
            sessionId: sessionId,
            deviceId: storedDeviceId
        )
    }

    func signUp(
        voucher: String,
        email: String,
        username: String,
        passwordHash: String,
        deviceId: String,
        systemVersion: String
    ) async throws {
        do {
            try await validateVoucher(voucher: voucher)

            let post = "user=\(username)&email=\(email)&pswrd=\(passwordHash)&deviceId=\(deviceId)&voucher_=\(voucher)&ios=\(systemVersion)" as NSString
            let postData = post.data(using: String.Encoding.ascii.rawValue)!

            let time = zeroTime(0).getCurrentMillis()
            let post_ = "/login/register:user=\(username)&email=\(email)&pswrd=\(passwordHash)&deviceId=\(deviceId)&voucher_=\(voucher):\(time):\(post.length)"

            let hmacSHA512 = CryptoJS.hmacSHA512()
            let hmacSec = hmacSHA512.hmac(username, secret: passwordHash) as NSString
            let hmacHash = hmacSHA512.hmac(post_, secret: hmacSec as String) as NSString

            let endpoint = Endpoint(
                path: "login/register",
                method: "POST",
                query: nil,
                body: postData,
                cacheKey: nil,
                absoluteURL: nil
            )

            let headers = HMACLoginHeaderProvider(
                contentLength: String(postData.count),
                hmacHash: hmacHash as String,
                microTime: String(time)
            )

            let data = try await apiClient.requestData(endpoint, headers: headers)
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] ?? [:]

            guard let success = json["success"] as? NSNumber, success.intValue == 1 else {
                let message = json["Message"] as? String ?? "Registration failed"
                throw AppError.httpError(statusCode: 400, message: message)
            }

            let prefs = UserDefaults.standard
            prefs.set(username, forKey: "USERNAME")
            prefs.set(1, forKey: "ISLOGGEDIN")
            prefs.set(0, forKey: "ISWEBLOGGEDIN")
            prefs.setValue(json["JSESSIONID"] as? String, forKey: "JSESSIONID")
            prefs.setValue(deviceId, forKey: "deviceId")
            prefs.setValue(json["X-Token"] as? String, forKey: "X-Token")
            prefs.synchronize()

            if let sessionId = json["JSESSIONID"] as? String {
                SecureStore.set(sessionId, for: "JSESSIONID")
            }
            if let token = json["X-Token"] as? String {
                SecureStore.set(token, for: "X-Token")
            }
        } catch {
            throw handleError(error)
        }
    }

    private func validateVoucher(voucher: String) async throws {
        guard let url = URL(string: URLManager.login("/voucher")) else {
            throw AppError.decodingFailed
        }

        var request = URLRequest(url: url)
        let post = "voucher=\(voucher)" as NSString
        let postData = post.data(using: String.Encoding.ascii.rawValue)!
        request.httpMethod = "POST"
        request.httpBody = postData
        request.setValue(String(postData.count), forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkFailure(underlying: URLError(.badServerResponse))
        }

        if http.statusCode == 412 {
            throw AppError.httpError(statusCode: http.statusCode, message: "Voucher is already used")
        }

        guard 200 ... 299 ~= http.statusCode else {
            throw AppError.httpError(statusCode: http.statusCode, message: "Voucher validation failed")
        }
    }
}

struct UserProfileModel {
    let username: String
    let email: String
    let profilePicture: String
}

struct SessionTokenModel {
    let token: String
    let sessionId: String
    let deviceId: String
}


//
//  BasketDataManager.swift
//  SwiftCinemas
//

import Foundation
import SwiftyJSON
import UIKit

/// Manages shopping basket, payments, and purchases
final class BasketDataManager: SharedDataManager, HasAppServices {
    static let shared = BasketDataManager()
    static var domain: String { "Basket" }

    var appServices: AppServices!

    private var loginGateway: LoginGatewayService { appServices.loginGateway }

    private init() {}

    // MARK: - Navigation Context

    /// Order ID for the in-progress payment (set before navigating to checkout)
    var currentOrderId: String?

    /// Seats-to-reserve string passed to fullcheckout2 (e.g. "A1-B2-")
    var currentSeatsToBeReserved: String?

    /// Basket items keyed by seatId (replaces global `BasketData_`)
    var basketItemsBySeatId: [Int: BasketItem] = [:]

    /// Seats-to-reserve payload keyed by screeningDateId (replaces global `Seats`)
    var seatsToReservePayloadByScreening: [String: String] = [:]

    /// Reset context after payment completes or is cancelled
    func resetNavigationContext() {
        currentOrderId = nil
        currentSeatsToBeReserved = nil
        basketItemsBySeatId = [:]
        seatsToReservePayloadByScreening = [:]
    }

    // MARK: - Fetch Methods

    /// Get Braintree client token for payment form
    func getClientToken() async throws -> ClientTokenModel {
        do {
            let data = try await loginGateway.getCheckOut()
            let json = try JSON(data: data)

            guard let clientToken = json["clientToken"].string else {
                throw AppError.decodingFailed
            }

            return ClientTokenModel(clientToken: clientToken)
        } catch {
            throw handleError(error)
        }
    }

    /// Submit payment and create purchase
    func submitPayment(nonce: String, orderId: String, seatsToBeReserved: String) async throws -> PurchaseModel {
        do {
            let postBody = "payment_method_nonce=\(nonce)&orderId=\(orderId)&seatsToBeReserved=\(seatsToBeReserved)"
            guard let bodyData = postBody.data(using: .utf8) else {
                throw AppError.networkFailure(underlying: NSError(domain: "Basket", code: -1))
            }

            let responseData = try await loginGateway.postCheckOut(body: bodyData)
            let json = try JSON(data: responseData)

            guard let status = json["status"].string else {
                throw AppError.decodingFailed
            }

            if status != "success" {
                let message = json["message"].string ?? "Payment failed"
                throw AppError.httpError(statusCode: 400, message: message)
            }

            guard let purchase = PurchaseModel(json: json) else {
                throw AppError.decodingFailed
            }

            return purchase
        } catch {
            throw handleError(error)
        }
    }

    /// Get current basket/purchases for user
    func getBasket() async throws -> [PurchaseModel] {
        do {
            let data = try await loginGateway.getCheckOut()
            let json = try JSON(data: data)

            guard let purchases = json["purchases"].array else {
                return []
            }

            return purchases.compactMap { PurchaseModel(json: $0) }
        } catch {
            throw handleError(error)
        }
    }

    /// Build `seatsToBeReserved` JSON payload expected by checkout endpoint.
    func makeSeatsToBeReservedPayload() throws -> String {
        let seatData = seatsToReservePayloadByScreening.map { key, value in
            ["screeningDateId": key, "seat": value] as NSDictionary
        }
        let payload: NSDictionary = ["seatsToBeReserved": seatData]
        let serialized = try JSONSerialization.data(withJSONObject: payload, options: [])
        guard let jsonString = String(data: serialized, encoding: .utf8) else {
            throw AppError.decodingFailed
        }
        return jsonString
    }
}


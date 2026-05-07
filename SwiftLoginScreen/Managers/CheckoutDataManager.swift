//
//  CheckoutDataManager.swift
//  SwiftCinemas
//

import Foundation
import SwiftyJSON
import UIKit

final class CheckoutDataManager: SharedDataManager, HasAppServices {
    static let shared = CheckoutDataManager()
    static var domain: String { "Checkout" }

    var appServices: AppServices!

    private var loginGateway: LoginGatewayService { appServices.loginGateway }

    private init() {}

    // MARK: - Navigation Context

    /// The purchase ID selected in PurchasesVC to show in PurchaseDetailVC
    var selectedPurchaseId: String?

    /// Reset all navigation context
    func resetNavigationContext() {
        selectedPurchaseId = nil
    }

    // MARK: - Checkout

    /// Fetch client token from the server.
    /// - Returns: A `ClientTokenModel` containing the client token and API key.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func fetchClientToken() async throws -> ClientTokenModel {
        do {
            let data = try await loginGateway.getCheckOut()
            let json = try JSON(data: data)

            guard let clientToken = json["clientToken"].string,
                  let apiKey = json["APIKEY"].string else {
                throw AppError.decodingFailed
            }

            return ClientTokenModel(clientToken: clientToken, apiKey: apiKey)
        } catch {
            throw handleError(error)
        }
    }

    /// Submit payment and complete checkout.
    /// - Parameters:
    ///   - paymentMethodNonce: The payment method nonce received from the payment gateway.
    ///   - orderId: The ID of the order being checked out.
    ///   - seatsToBeReserved: A string representation of the seats to be reserved.
    /// - Returns: A `CheckoutResultModel` containing the result of the checkout process.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func checkout(
        paymentMethodNonce: String,
        orderId: String,
        seatsToBeReserved: String
    ) async throws -> CheckoutResultModel {
        do {
            let json = try await postCheckout(
                paymentMethodNonce: paymentMethodNonce,
                orderId: orderId,
                seatsToBeReserved: seatsToBeReserved
            )
            var result = CheckoutResultModel(json: json)
            if !result.isSuccess {
                result.errorMessage = interpretPaymentError(result.errorMessage)
            }
            return result
        } catch {
            throw handleError(error)
        }
    }

    // MARK: - Purchases

    /// Fetch all user purchases.
    /// - Returns: An array of `PurchaseSummaryModel` containing summaries of all purchases.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func fetchAllPurchases() async throws -> [PurchaseSummaryModel] {
        do {
            let data = try await loginGateway.getAllPurchases()
            let json = try JSON(data: data)
            return json["purchases"].arrayValue.compactMap { PurchaseSummaryModel(json: $0) }
        } catch {
            throw handleError(error)
        }
    }

    /// Fetch detailed ticket information for a specific purchase.
    /// - Parameter purchaseId: The ID of the purchase for which to fetch ticket details.
    /// - Returns: An array of `TicketDetailModel` containing details of the tickets in the purchase.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func fetchTickets(purchaseId: String) async throws -> [TicketDetailModel] {
        do {
            let data = try await loginGateway.getManagePurchases(purchaseId: purchaseId)
            let json = try JSON(data: data)
            return json["tickets"].arrayValue.compactMap { TicketDetailModel(json: $0) }
        } catch {
            throw handleError(error)
        }
    }

    /// Refund a specific purchase.
    /// - Parameter purchaseId: The ID of the purchase to refund.
    /// - Returns: A boolean value indicating whether the refund was successful.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func refundPurchase(purchaseId: String) async throws -> Bool {
        do {
            let post = "purchaseId=\(purchaseId)" as NSString
            guard let body = post.data(using: String.Encoding.ascii.rawValue) else {
                throw AppError.decodingFailed
            }
            let data = try await loginGateway.postManagePurchases(body: body)
            let json = try JSON(data: data)
            return json["Success"].string == "true"
        } catch {
            throw handleError(error)
        }
    }

    /// Cancel specific tickets in a purchase.
    /// - Parameters:
    ///   - purchaseId: The ID of the purchase containing the tickets to cancel.
    ///   - ticketIds: An array of ticket IDs to cancel.
    /// - Returns: A boolean value indicating whether the cancellation was successful.
    /// - Throws: An error of type `AppError` if the network request fails or the response is invalid.
    func cancelTickets(purchaseId: String, ticketIds: [Int]) async throws -> Bool {
        do {
            let payload: NSDictionary = ["ticketIds": ticketIds]
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            guard let encoded = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) else {
                throw AppError.decodingFailed
            }

            let post = "purchaseId=\(purchaseId)&ticketsToBeCancelled=\(encoded)" as NSString
            guard let body = post.data(using: String.Encoding.ascii.rawValue) else {
                throw AppError.decodingFailed
            }

            let data = try await loginGateway.postManagePurchases(body: body)
            let json = try JSON(data: data)
            return json["Success"].string == "true"
        } catch {
            throw handleError(error)
        }
    }

    // MARK: - Private Methods

    private func postCheckout(
        paymentMethodNonce: String,
        orderId: String,
        seatsToBeReserved: String
    ) async throws -> JSON {
        let postBody = "payment_method_nonce=\(paymentMethodNonce)&orderId=\(orderId)&seatsToBeReserved=\(seatsToBeReserved)"
        guard let bodyData = postBody.data(using: .utf8) else {
            throw AppError.networkFailure(underlying: NSError(domain: "Checkout", code: -1))
        }
        let responseData = try await loginGateway.postCheckOut(body: bodyData)
        return try JSON(data: responseData)
    }

    private func interpretPaymentError(_ rawMessage: String?) -> String {
        let lowercased = (rawMessage ?? "").lowercased()

        if lowercased.contains("nonce") || lowercased.contains("payment method") {
            return "Your payment method could not be verified. Please re-enter card details or try another method."
        }
        if lowercased.contains("declined") {
            return "Your bank declined the payment. Please use a different card or contact your bank."
        }
        if lowercased.contains("insufficient") {
            return "Insufficient funds. Please use another payment method."
        }
        if lowercased.contains("gateway") || lowercased.contains("network") || lowercased.contains("timeout") {
            return "Payment service is temporarily unavailable. Please try again in a moment."
        }
        if let rawMessage, !rawMessage.isEmpty {
            return rawMessage
        }
        return "Payment could not be completed. Please try again."
    }
}

// MARK: - Checkout Models

struct ClientTokenModel {
    let clientToken: String
    let apiKey: String
}

struct CheckoutResultModel {
    let isSuccess: Bool
    let responseText: String?
    let status: String?
    let amount: String?
    let taxAmount: String?
    let reservedSeats: [SeatModel]
    let tickets: [TicketDetailModel]
    let failedTickets: [TicketDetailModel]
    var errorMessage: String?

    init(json: JSON) {
        responseText = json["ResponseText"].string
        status = json["Status"].string ?? json["status"].string
        if let amountString = json["Amount"].string {
            amount = amountString
        } else if let amountNumber = json["Amount"].number {
            amount = amountNumber.stringValue
        } else {
            amount = nil
        }
        if let taxString = json["TaxAmount"].string {
            taxAmount = taxString
        } else if let taxNumber = json["TaxAmount"].number {
            taxAmount = taxNumber.stringValue
        } else {
            taxAmount = nil
        }
        reservedSeats = json["seatsforscreen"].arrayValue.compactMap { SeatModel(json: $0) }
        tickets = json["tickets"].arrayValue.compactMap { TicketDetailModel(json: $0) }
        failedTickets = json["failedTickets"].arrayValue.compactMap { TicketDetailModel(json: $0) }
        errorMessage = json["Error"].string ?? json["Error with Transaction"].string ?? json["message"].string
        isSuccess = responseText == "hello" || status == "success"
    }
}

struct PurchaseSummaryModel {
    let orderId: String
    let purchaseId: String
    let movieName: String
    let venueName: String
    let moviePicture: String
    let screeningDate: String
    let purchaseDate: String

    init?(json: JSON) {
        guard let orderId = json["orderId"].string,
              let purchaseId = json["purchaseId"].string,
              let movieName = json["movie_name"].string,
              let venueName = json["venue_name"].string,
              let moviePicture = json["movie_picture"].string,
              let screeningDate = json["screeningDate"].string,
              let purchaseDate = json["purchaseDate"].string else {
            return nil
        }

        self.orderId = orderId
        self.purchaseId = purchaseId
        self.movieName = movieName
        self.venueName = venueName
        self.moviePicture = moviePicture
        self.screeningDate = screeningDate
        self.purchaseDate = purchaseDate
    }
}

struct TicketDetailModel {
    let movieName: String
    let moviePicture: String
    let venueName: String
    let seatRow: String
    let seatNumber: String
    let price: Int
    let tax: Double
    let screenId: String
    let screeningDate: String
    let ticketId: Int

    init?(json: JSON) {
        guard let movieName = json["movie_name"].string,
              let moviePicture = json["movie_picture"].string,
              let venueName = json["venue_name"].string,
              let seatRow = json["seats_seatRow"].string,
              let seatNumber = json["seats_seatNumber"].string,
              let price = json["price"].int,
              let tax = json["tax"].double,
              let screenId = json["screen_screenId"].string,
              let screeningDate = json["screening_date"].string,
              let ticketId = json["ticketId"].int else {
            return nil
        }

        self.movieName = movieName
        self.moviePicture = moviePicture
        self.venueName = venueName
        self.seatRow = seatRow
        self.seatNumber = seatNumber
        self.price = price
        self.tax = tax
        self.screenId = screenId
        self.screeningDate = screeningDate
        self.ticketId = ticketId
    }
}

typealias ClientToken = ClientTokenModel
typealias Purchase = PurchaseSummaryModel
typealias PurchaseModel = PurchaseSummaryModel

// SeatsDataManager.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SwiftyJSON
import UIKit

@MainActor
final class SeatsDataManager: SharedDataManager, HasAppServices {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = SeatsDataManager()

    static var domain: String {
        "Seats"
    }

    var appServices: AppServices!

    // MARK: - Navigation Context (replaces global SeatsData_ and BasketData_)

    /// All seat data for the current screening (replaces global `SeatsData_`)
    var allSeats: [SeatModel] = []

    /// Seat IDs the user has currently selected/toggled
    var selectedSeatIds: [Int] = []

    /// Seat numbers for selected seats (e.g. "A1", "B3") — used in checkout payload
    var selectedSeatNumbers: [String] = []

    /// Reset all navigation context (call when starting a new booking flow or after checkout)
    func resetNavigationContext() {
        allSeats = []
        selectedSeatIds = []
        selectedSeatNumbers = []
    }

    // MARK: - Fetch Methods

    /// Fetch seats for a screening with full availability data
    func fetchSeats(screeningDateId: Int) async throws -> [SeatModel] {
        do {
            let data = try await mbooks.seats(screeningDateId: String(screeningDateId))
            let json = try JSON(data: data)

            guard let seatArray = json["seatsforscreen"].array else {
                throw AppError.decodingFailed
            }

            let parsed = seatArray.compactMap { SeatModel(json: $0) }
            allSeats = parsed
            return parsed
        } catch {
            throw handleError(error)
        }
    }

    /// Reserve seats optimistically in local state after validating availability.
    ///
    /// Backend performs the final pessimistic lock at checkout time; this helper keeps UI state coherent.
    func reserveSeats(screeningDateId: Int, seats: [String]) async throws -> [SeatModel] {
        do {
            let latest = try await fetchSeats(screeningDateId: screeningDateId)
            let requested = Set(seats.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() })

            guard !requested.isEmpty else {
                return latest
            }

            let unavailable = latest
                .filter { requested.contains($0.seatNumber.uppercased()) && $0.isReserved }
                .map(\.seatNumber)

            if !unavailable.isEmpty {
                throw AppError.httpError(statusCode: 409, message: "Seat(s) already reserved: \(unavailable.joined(separator: ", "))")
            }

            let updated = latest.map { seat -> SeatModel in
                guard requested.contains(seat.seatNumber.uppercased()) else { return seat }
                return Seat(
                    seatId: seat.seatId,
                    seatNumber: seat.seatNumber,
                    seatRow: seat.seatRow,
                    isReserved: true,
                    price: seat.price,
                    tax: seat.tax
                )
            }

            allSeats = updated
            selectedSeatNumbers = updated.filter { $0.isReserved && requested.contains($0.seatNumber.uppercased()) }.map(\.seatNumber)
            selectedSeatIds = updated.filter { requested.contains($0.seatNumber.uppercased()) }.map(\.seatId)
            return updated
        } catch {
            throw handleError(error)
        }
    }

    /// Group seats by row for table view rendering
    func groupByRow(_ seats: [SeatModel]) -> [String: [SeatModel]] {
        var grouped: [String: [SeatModel]] = [:]
        for seat in seats {
            if grouped[seat.seatRow] == nil {
                grouped[seat.seatRow] = []
            }
            grouped[seat.seatRow]?.append(seat)
        }
        return grouped
    }

    /// Get unique rows sorted alphabetically
    func getRows(_ seats: [SeatModel]) -> [String] {
        Array(Set(seats.map { $0.seatRow })).sorted()
    }

    // MARK: Private

    private var mbooks: MbooksService {
        appServices.mbooks
    }
}

struct Seat {
    // MARK: Lifecycle

    init(seatId: Int, seatNumber: String, seatRow: String, isReserved: Bool, price: Int, tax: Double) {
        self.seatId = seatId
        self.seatNumber = seatNumber
        self.seatRow = seatRow
        self.isReserved = isReserved
        self.price = price
        self.tax = tax
    }

    init?(json: JSON) {
        guard let id = json["seatId"].int,
              let number = json["seatNumber"].string,
              let row = json["seatRow"].string,
              let reserved = json["isReserved"].string,
              let price = json["price"].int,
              let tax = json["tax"].double
        else {
            return nil
        }
        seatId = id
        seatNumber = number
        seatRow = row
        isReserved = reserved == "1"
        self.price = price
        self.tax = tax
    }

    // MARK: Internal

    let seatId: Int
    let seatNumber: String
    let seatRow: String
    let isReserved: Bool
    let price: Int
    let tax: Double
}

typealias SeatModel = Seat

// DatesDataManager.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SwiftyJSON

@MainActor
final class DatesDataManager: SharedDataManager, HasAppServices {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = DatesDataManager()

    static var domain: String {
        "Dates"
    }

    var appServices: AppServices!

    // MARK: - Navigation Context

    /// The screening date ID selected by the user (replaces global `screeningDateId`)
    var selectedScreeningDateId: String?

    /// Human-readable date text for display in downstream screens
    var selectedScreeningDateText: String?

    /// Available dates for the current venue/movie context
    var availableDates: [ScreeningDate] = []

    /// Reset all navigation context (call when starting a new booking flow)
    func resetNavigationContext() {
        selectedScreeningDateId = nil
        selectedScreeningDateText = nil
        availableDates = []
    }

    // MARK: - Fetch Methods

    /// Fetch screening dates for movie at location
    func fetchDates(locationId: Int, movieId: Int) async throws -> [DateModel] {
        do {
            let data = try await mbooks.dates(locationId: locationId, movieId: movieId)
            let json = try JSON(data: data)

            guard let dateArray = json["dates"].array else {
                throw AppError.decodingFailed
            }

            let parsed = sort(dateArray.compactMap { DateModel(json: $0) })
            availableDates = parsed
            return parsed
        } catch {
            throw handleError(error)
        }
    }

    func displayText(for screeningDate: ScreeningDate) -> String {
        let normalized = screeningDate.date.split(separator: ".").first.map(String.init) ?? screeningDate.date
        guard !normalized.isEmpty else { return screeningDate.date }
        return String.formatDate(date: Date.formatDate(dateString: normalized))
    }

    // MARK: Private

    private var mbooks: MbooksService {
        appServices.mbooks
    }

    private func sort(_ dates: [DateModel]) -> [DateModel] {
        dates.sorted {
            guard let lhs = parseDate($0.date), let rhs = parseDate($1.date) else {
                return $0.date < $1.date
            }
            return lhs < rhs
        }
    }

    private func parseDate(_ raw: String) -> Date? {
        let normalized = raw.split(separator: ".").first.map(String.init) ?? raw
        guard !normalized.isEmpty else { return nil }
        return Date.formatDate(dateString: normalized)
    }
}

struct ScreeningDate {
    // MARK: Lifecycle

    init?(json: JSON) {
        guard let screeningId = json["screeningDateId"].string
            ?? json["screeningDateId"].int.map(String.init)
            ?? json["screeningDatesId"].string
            ?? json["screeningDatesId"].int.map(String.init)
        else {
            return nil
        }

        let dateValue = json["date"].string
            ?? json["screeningDate"].string
            ?? ""

        screeningDateId = screeningId
        date = dateValue
        time = json["time"].string
    }

    // MARK: Internal

    let screeningDateId: String
    let date: String
    let time: String?
}

typealias DateModel = ScreeningDate
typealias ScreeningDateModel = ScreeningDate

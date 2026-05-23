// AdminScreeningsDataManager.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SwiftyJSON
import UIKit

/// Owns admin movie/venue screening list data and admin write operations.
@MainActor
final class AdminDataManager: @MainActor SharedDataManager, @MainActor HasAppServices {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = AdminDataManager()

    static var domain: String {
        "Admin"
    }

    var appServices: AppServices!

    var screeningsForAdminUpdate: [AdminScreeningModel] = []
    var selectedScreen: AdminScreeningModel?

    func resetContext() {
        screeningsForAdminUpdate = []
    }

    func fetchScreenings(category: String? = nil) async throws -> [AdminScreeningModel] {
        do {
            let data: Data
            if let category, !category.isEmpty {
                data = try await mbooks.adminMoviesOnVenuesCategorized(query: ["category": category])
            } else {
                data = try await mbooks.adminMoviesOnVenues()
            }
            let screenings = try parseScreenings(from: data)
            screeningsForAdminUpdate = screenings
            return screenings
        } catch {
            throw handleError(error)
        }
    }

    func searchScreenings(match: String) async throws -> [AdminScreeningModel] {
        do {
            let data = try await mbooks.adminMoviesOnVenuesSearch(query: ["match": match])
            let screenings = try parseScreenings(from: data)
            screeningsForAdminUpdate = screenings
            return screenings
        } catch {
            throw handleError(error)
        }
    }

    func addScreen(body: [String: Any]) async throws -> ScreenMutationResultModel {
        do {
            let data = try await mbooks.adminAddScreen(body: body)
            let json = try JSON(data: data)
            guard let dictionary = json.object as? NSDictionary else {
                throw AppError.decodingFailed
            }
            return ScreenMutationResultModel(add: dictionary)
        } catch {
            throw handleError(error)
        }
    }

    func updateScreen(body: [String: Any]) async throws -> ScreenMutationResultModel {
        do {
            let data = try await mbooks.adminUpdateScreen(body: body)
            let json = try JSON(data: data)
            guard let dictionary = json.object as? NSDictionary else {
                throw AppError.decodingFailed
            }
            return ScreenMutationResultModel(add: dictionary)
        } catch {
            throw handleError(error)
        }
    }

    func deleteScreen(body: [String: Any]) async throws -> Bool {
        do {
            let data = try await mbooks.adminDeleteScreen(body: body)
            let json = try JSON(data: data)
            return json["screeningDatesId"].string != nil
        } catch {
            throw handleError(error)
        }
    }

    // MARK: Private

    private var mbooks: MbooksService {
        appServices.mbooks
    }

    private func parseScreenings(from data: Data) throws -> [AdminScreeningModel] {
        let json = try JSON(data: data)
        guard let list = json["venues"].array else {
            return []
        }
        return list.compactMap {
            guard let dictionary = $0.object as? NSDictionary else { return nil }
            return AdminScreeningModel(add: dictionary)
        }
    }
}

struct ScreenMutationResultModel {
    // MARK: Lifecycle

    init(add: NSDictionary) {
        movie = add["movie"] as? String ?? ""
        date = add["date"] as? String ?? ""
        venue = add["venue"] as? String ?? ""
        screeningId = add["ScreeningId"] as? String ?? ""
    }

    // MARK: Internal

    let movie: String
    let date: String
    let venue: String
    let screeningId: String
}

struct AdminScreeningModel {
    // MARK: Lifecycle

    init(add: NSDictionary) {
        movie = add["movie"] as? String ?? ""
        movieId = add["movieId"] as? String ?? ""
        date = add["date"] as? String ?? ""
        venue = add["venue"] as? String ?? ""
        venueId = add["venueId"] as? String ?? ""
        screeningId = add["ScreeningId"] as? String ?? ""
        category = add["category"] as? String ?? ""
        screeningDatesId = add["screeningDatesId"] as? String ?? ""
    }

    // MARK: Internal

    let movie: String
    let movieId: String
    let date: String
    let venue: String
    let venueId: String
    let screeningId: String
    let category: String
    let screeningDatesId: String
}

typealias AdminScreeningsDataManager = AdminDataManager

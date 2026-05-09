//
//  AdminScreeningsDataManager.swift
//  SwiftCinemas
//

import Foundation
import SwiftyJSON
import UIKit

/// Owns admin movie/venue screening list data and admin write operations.
final class AdminDataManager: SharedDataManager, HasAppServices {
    static let shared = AdminDataManager()
    static var domain: String { "Admin" }

    var appServices: AppServices!

    private var mbooks: MbooksService { appServices.mbooks }

    /// Replaces legacy global `ScreenData_2`.
    var screeningsForAdminUpdate: [AdminScreeningModel] = []

    private init() {}

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

    /// Update movie selection for the currently edited admin screening context.
    func updateMovie(movie: MovieDataModel) async throws -> MovieDataModel {
        do {
            let ctx = resolveScreenContext()
            let body: [String: Any] = [
                "venue": ctx.venue,
                "venueId": ctx.venueId,
                "movieId": movie.movieIdString,
                "date": ctx.date,
                "ScreeningDatesId": ctx.screeningDatesId,
                "screenId": ctx.screenId,
                "category": ctx.category,
            ]

            let result = try await updateScreen(body: body)
            if result.screeningId.contains("Error") {
                throw AppError.httpError(statusCode: 409, message: result.screeningId)
            }

            return movie
        } catch {
            throw handleError(error)
        }
    }

    /// Update venue selection for the currently edited admin screening context.
    func updateVenue(venue: VenueModel) async throws -> VenueModel {
        do {
            let ctx = resolveScreenContext()
            let body: [String: Any] = [
                "venue": venue.name,
                "venueId": String(venue.venuesId),
                "movieId": ctx.movieId,
                "date": ctx.date,
                "ScreeningDatesId": ctx.screeningDatesId,
                "screenId": ctx.screenId,
                "category": ctx.category,
            ]

            let result = try await updateScreen(body: body)
            if result.screeningId.contains("Error") {
                throw AppError.httpError(statusCode: 409, message: result.screeningId)
            }

            return venue
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

    private func resolveScreenContext() -> AdminScreenContext {
        let selected = screeningsForAdminUpdate.first { model in
            (!addScreeningDateId.isEmpty && model.screeningDatesId == addScreeningDateId)
                || (!addScreeningID.isEmpty && model.screeningId == addScreeningID)
        }

        return AdminScreenContext(
            venue: !addVenue.isEmpty ? addVenue : (selected?.venue ?? ""),
            venueId: !addVenueId.isEmpty ? addVenueId : (selected?.venueId ?? ""),
            movieId: !addMovieId.isEmpty ? addMovieId : (selected?.movieId ?? ""),
            date: !addScreeningDate.isEmpty ? addScreeningDate : (selected?.date ?? ""),
            screenId: !addScreeningID.isEmpty ? addScreeningID : (selected?.screeningId ?? ""),
            category: !addCategory.isEmpty ? addCategory : (selected?.category ?? ""),
            screeningDatesId: !addScreeningDateId.isEmpty ? addScreeningDateId : (selected?.screeningDatesId ?? "")
        )
    }
}

private struct AdminScreenContext {
    let venue: String
    let venueId: String
    let movieId: String
    let date: String
    let screenId: String
    let category: String
    let screeningDatesId: String
}

struct ScreenMutationResultModel {
    let movie: String
    let date: String
    let venue: String
    let screeningId: String

    init(add: NSDictionary) {
        movie = add["movie"] as? String ?? ""
        date = add["date"] as? String ?? ""
        venue = add["venue"] as? String ?? ""
        screeningId = add["ScreeningId"] as? String ?? ""
    }
}

struct AdminScreeningModel {
    let movie: String
    let movieId: String
    let date: String
    let venue: String
    let venueId: String
    let screeningId: String
    let category: String
    let screeningDatesId: String

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
}

typealias AdminScreeningsDataManager = AdminDataManager


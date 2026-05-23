// VenuesDataManager.swift
// Created by Gyorgy Gaspar on 2026.05.23.

import Foundation
import SwiftyJSON
import UIKit

@MainActor
final class VenuesDataManager: SharedDataManager, HasAppServices {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = VenuesDataManager()

    static var domain: String {
        "Venues"
    }

    var appServices: AppServices!

    // MARK: - Navigation Context

    /// The venue selected by the user; passed to Dates/Seats screens
    var selectedVenue: VenueModel?

    /// Venues loaded for the currently selected movie.
    var venuesForSelectedMovie: [VenueModel] = []

    /// Fast lookup cache for venues by ID.
    var venuesCacheById: [String: VenueModel] = [:]

    /// Screen list cache keyed by venue ID.
    var screensCacheByVenueId: [String: [ScreenDataModel]] = [:]

    /// Seat list cache keyed by `screenId|date`.
    var seatsCacheByScreenAndDate: [String: [SeatModel]] = [:]

    /// Movie and venue combinations shown when a location is opened from the map flow.
    var moviesForSelectedLocation: [VenueMovieSelection] = []

    /// Reset all navigation context (call when starting a new booking flow)
    func resetNavigationContext() {
        selectedVenue = nil
        venuesForSelectedMovie = []
        venuesCacheById = [:]
        screensCacheByVenueId = [:]
        seatsCacheByScreenAndDate = [:]
        moviesForSelectedLocation = []
    }

    // MARK: - Fetch Methods

    /// Fetch venues showing a specific movie
    func fetchVenuesForMovie(movieId: String) async throws -> [VenueModel] {
        do {
            let data = try await mbooks.venue(movieId: movieId)
            let json = try JSON(data: data)

            guard let venueArray = json["venues"].array else {
                throw AppError.decodingFailed
            }

            let venues = venueArray.compactMap { VenueModel(json: $0) }
            venuesForSelectedMovie = venues
            venuesCacheById = Dictionary(uniqueKeysWithValues: venues.map { (String($0.venuesId), $0) })

            // Persist each venue by its own ID for direct venue-level cache lookups.
            for venue in venues {
                if let encoded = encodeVenue(venue) {
                    await MainActor.run {
                        self.realmCache.save(encoded, for: venueCacheKey(venueId: String(venue.venuesId)))
                    }
                }
            }
            return venues
        } catch {
            throw handleError(error)
        }
    }

    /// Derive screens for a venue from already fetched venue payloads.
    func getScreens(venueId: String) async throws -> [ScreenDataModel] {
        if let cached = screensCacheByVenueId[venueId] {
            return cached
        }

        let venue: VenueModel?
        if let cachedVenue = venuesCacheById[venueId] {
            venue = cachedVenue
        } else if let cachedVenue = await loadVenueFromRealm(venueId: venueId) {
            venuesCacheById[venueId] = cachedVenue
            venue = cachedVenue
        } else if let selectedVenue, String(selectedVenue.venuesId) == venueId {
            venue = selectedVenue
        } else {
            if let selectedMovieId = MoviesDataManager.shared.selectedMovie?.movieIdString {
                _ = try await fetchVenuesForMovie(movieId: selectedMovieId)
            }
            venue = venuesCacheById[venueId]
        }

        guard let venue else {
            throw AppError.decodingFailed
        }

        let screens = parseScreenIds(from: venue.screenId).map {
            ScreenDataModel(screenId: $0, venueId: venueId)
        }
        screensCacheByVenueId[venueId] = screens
        return screens
    }

    /// Resolve seats for a given screen/date combination by chaining dates -> seats endpoints.
    func getSeatsForScreen(screenId: String, date: String) async throws -> [SeatModel] {
        let cacheKey = "\(screenId)|\(date)"
        if let cached = seatsCacheByScreenAndDate[cacheKey] {
            return cached
        }

        let datesData = try await mbooks.dates(screenId: screenId)
        let datesJSON = try JSON(data: datesData)
        let dates = datesJSON["dates"].arrayValue.compactMap { ScreeningDateModel(json: $0) }

        let normalizedTarget = normalizeDate(date)
        let selected = dates.first {
            normalizeDate($0.date) == normalizedTarget || normalizedTarget.isEmpty
        } ?? dates.first

        guard let selected else {
            throw AppError.decodingFailed
        }

        let seatsData = try await mbooks.seats(screeningDateId: selected.screeningDateId)
        let seatsJSON = try JSON(data: seatsData)
        guard let seatArray = seatsJSON["seatsforscreen"].array else {
            throw AppError.decodingFailed
        }
        let seats = seatArray.compactMap { SeatModel(json: $0) }
        seatsCacheByScreenAndDate[cacheKey] = seats
        return seats
    }

    /// Fetch movies available at a specific location
    func fetchMoviesAtLocation(locationId: String) async throws -> [VenueMovieModel] {
        do {
            let data = try await mbooks.venueMovies(locationId: locationId)
            let json = try JSON(data: data)

            guard let movieArray = json["movies"].array else {
                throw AppError.decodingFailed
            }

            return movieArray.compactMap { VenueMovieModel(json: $0) }
        } catch {
            throw handleError(error)
        }
    }

    /// Fetch movie cards plus venue metadata for the map -> venue flow.
    func fetchVenueMovieSelections(locationId: String) async throws -> [VenueMovieSelection] {
        do {
            let data = try await mbooks.venueMovies(locationId: locationId)
            let json = try JSON(data: data)
            let movieEntries = json["movies"].arrayValue.compactMap { raw -> (movie: MovieDataModel, raw: JSON)? in
                guard let movie = MovieDataModel(json: raw) else { return nil }
                return (movie, raw)
            }
            let venues = json["venue"].arrayValue.compactMap { VenueSelectionVenue(json: $0) }
            guard !movieEntries.isEmpty else {
                moviesForSelectedLocation = []
                return []
            }

            let locationInt = Int(locationId)
            let screeningDateByMovieId = await fetchScreeningDatesByMovieId(
                movies: movieEntries.map(\.movie),
                locationId: locationInt
            )

            let fallbackVenue = venues.first
            let selections: [VenueMovieSelection] = movieEntries.compactMap { entry -> VenueMovieSelection? in
                let movie = entry.movie
                let matchingVenue = venues.first(where: { $0.name == movie.name })
                    ?? fallbackVenue
                guard let matchingVenue else { return nil }

                let category = extractCategoryText(from: entry.raw)
                let payloadDate = extractScreeningDateText(from: entry.raw)
                let endpointDate = screeningDateByMovieId[movie.movieId]

                return VenueMovieSelection(
                    movie: movie,
                    venue: matchingVenue,
                    category: category,
                    screeningDate: payloadDate ?? endpointDate
                )
            }
            moviesForSelectedLocation = selections
            return selections
        } catch {
            throw handleError(error)
        }
    }

    // MARK: Private

    private let realmCache: ResponseCache = RealmResponseCache()

    private var mbooks: MbooksService {
        appServices.mbooks
    }

    private func extractCategoryText(from json: JSON) -> String? {
        let direct = json["category"].string
            ?? json["genre"].string
            ?? json["movie_category"].string
        if let direct, !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return direct
        }

        let fromArray = json["categories"].arrayValue
            .compactMap { $0.string }
            .first
        if let fromArray, !fromArray.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromArray
        }
        return nil
    }

    private func extractScreeningDateText(from json: JSON) -> String? {
        let raw = json["screeningDate"].string
            ?? json["screening_date"].string
            ?? json["date"].string
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return raw
    }

    private func fetchScreeningDatesByMovieId(movies: [MovieDataModel], locationId: Int?) async -> [Int: String] {
        guard let locationId else { return [:] }
        var result: [Int: String] = [:]
        let service = mbooks

        await withTaskGroup(of: (Int, String?).self) { group in
            for movie in movies {
                let movieId = movie.movieId
                group.addTask {
                    do {
                        let data = try await service.dates(locationId: locationId, movieId: movieId)
                        let json = try JSON(data: data)
                        let firstDate = json["dates"].arrayValue
                            .compactMap { ScreeningDateModel(json: $0)?.date }
                            .first
                        return (movieId, firstDate)
                    } catch {
                        return (movieId, nil)
                    }
                }
            }

            for await (movieId, dateText) in group {
                guard let dateText, !dateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                result[movieId] = dateText
            }
        }
        return result
    }

    private func parseScreenIds(from raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;| ")
        return raw
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizeDate(_ raw: String) -> String {
        raw.split(separator: ".").first.map(String.init) ?? raw
    }

    private func venueCacheKey(venueId: String) -> String {
        "venues/by-id/\(venueId)"
    }

    private func encodeVenue(_ venue: VenueModel) -> Data? {
        let payload: [String: Any] = [
            "venuesId": venue.venuesId,
            "name": venue.name,
            "address": venue.address,
            "venues_picture": venue.venuesPicture,
            "screen_screenId": venue.screenId,
            "locationId": venue.locationId,
        ]
        return try? JSONSerialization.data(withJSONObject: payload, options: [])
    }

    private func loadVenueFromRealm(venueId: String) async -> VenueModel? {
        await MainActor.run {
            guard let data = self.realmCache.cachedResponse(for: venueCacheKey(venueId: venueId)),
                  let object = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dictionary = object as? [String: Any]
            else {
                return nil
            }
            return VenueModel(json: JSON(dictionary))
        }
    }
}

struct Screen {
    let screenId: String
    let venueId: String
}

struct Venue {
    // MARK: Lifecycle

    init(venuesId: Int, name: String, address: String, venuesPicture: String, screenId: String, locationId: Int) {
        self.venuesId = venuesId
        self.name = name
        self.address = address
        self.venuesPicture = venuesPicture
        self.screenId = screenId
        self.locationId = locationId
    }

    init?(json: JSON) {
        let id = json["venuesId"].int ?? Int(json["venuesId"].string ?? "")
        let name = json["name"].string
        let address = json["address"].string ?? json["formatted_address"].string ?? ""
        let picture = json["venues_picture"].string ?? json["thumbnail"].string ?? ""
        let screenId = json["screen_screenId"].string
            ?? json["screen_screenId"].int.map(String.init)
            ?? ""
        let locId = json["locationId"].int ?? Int(json["locationId"].string ?? "")

        guard let id,
              let name,
              let locId
        else {
            return nil
        }
        venuesId = id
        self.name = name
        self.address = address
        venuesPicture = picture
        self.screenId = screenId
        locationId = locId
    }

    // MARK: Internal

    let venuesId: Int
    let name: String
    let address: String
    let venuesPicture: String
    let screenId: String
    let locationId: Int
}

struct VenueMovie {
    // MARK: Lifecycle

    init?(json: JSON) {
        guard let id = json["movieId"].string ?? json["movieId"].int.map(String.init),
              let name = json["name"].string
        else {
            return nil
        }
        movieId = id
        self.name = name
    }

    // MARK: Internal

    let movieId: String
    let name: String
}

struct VenueSelectionVenue {
    // MARK: Lifecycle

    init?(json: JSON) {
        let venuesId = json["venuesId"].int ?? Int(json["venuesId"].string ?? "")
        let name = json["name"].string
        let address = json["address"].string ?? json["formatted_address"].string ?? ""
        let venuesPicture = json["venues_picture"].string ?? json["thumbnail"].string ?? ""
        let screenId = json["screen_screenId"].string
            ?? json["screen_screenId"].int.map(String.init)
            ?? ""

        guard let venuesId,
              let name
        else {
            return nil
        }

        self.venuesId = venuesId
        self.name = name
        self.address = address
        self.venuesPicture = venuesPicture
        self.screenId = screenId
    }

    // MARK: Internal

    let venuesId: Int
    let name: String
    let address: String
    let venuesPicture: String
    let screenId: String
}

struct VenueMovieSelection {
    let movie: MovieDataModel
    let venue: VenueSelectionVenue
    let category: String?
    let screeningDate: String?
}

typealias VenueModel = Venue
typealias VenueMovieModel = VenueMovie
typealias ScreenDataModel = Screen

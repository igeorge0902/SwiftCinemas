//
//  MoviesDataManager.swift
//  SwiftCinemas
//

import Foundation
import SwiftyJSON
import UIKit

final class MoviesDataManager: SharedDataManager, HasAppServices {
    static let shared = MoviesDataManager()
    static var domain: String { "Movies" }

    var appServices: AppServices!

    private var mbooks: MbooksService { appServices.mbooks }
    private var images: ImageResourceService { appServices.images }
    private var rapidMovieDatabase: RapidMovieDatabaseService { appServices.rapidMovieDatabase }
    private let realmCache: ResponseCache = RealmResponseCache()

    private init() {}

    // MARK: - Navigation Context

    /// The movie selected by the user; passed to Venues/MovieDetail screens
    var selectedMovie: MovieDataModel?

    /// Last browse payload used by movie list screens.
    var browseList: [MovieDataModel] = []

    /// Last search payload used by movie list screens.
    var searchList: [MovieDataModel] = []

    /// Reset all navigation context (call when starting a new booking flow)
    func resetNavigationContext() {
        selectedMovie = nil
        browseList = []
        searchList = []
    }

    // MARK: - Fetch Methods

    /// Fetch paginated movies
    func fetchPaging(query: [String: String]) async throws -> [MovieDataModel] {
        do {
            let data = try await mbooks.moviesPaging(query: query)
            let json = try JSON(data: data)

            guard let movieArray = json["movies"].array else {
                throw AppError.decodingFailed
            }

            let movies = movieArray.compactMap { MovieDataModel(json: $0) }
            browseList = movies

            // Explicit manager-level Realm cache per movie ID; save() replaces prior key entries.
            await persistMoviesToRealmCache(movies)
            return movies
        } catch {
            throw handleError(error)
        }
    }

    /// Search movies by term
    func search(query: [String: String]) async throws -> [MovieDataModel] {
        do {
            let data = try await mbooks.moviesSearch(query: query)
            let json = try JSON(data: data)

            let movieArray = json["searchedMovies"].array ?? json["movies"].array
            guard let movieArray else {
                throw AppError.decodingFailed
            }

            let movies = movieArray.compactMap { MovieDataModel(json: $0) }
            searchList = movies
            await persistMoviesToRealmCache(movies)
            return movies
        } catch {
            throw handleError(error)
        }
    }

    /// Fetch trending movies
    func fetchTrending(limit: Int = 5, days: Int? = nil) async throws -> [MovieDataModel] {
        do {
            let data = try await mbooks.trendingMovies(limit: limit, days: days)
            let json = try JSON(data: data)

            let movieArray = json["trendingMovies"].array
                ?? json["movies"].array
                ?? json["searchedMovies"].array

            guard let movieArray else {
                throw AppError.decodingFailed
            }

            let movies = movieArray.compactMap { MovieDataModel(json: $0) }
            return Array(movies.prefix(limit))
        } catch {
            throw handleError(error)
        }
    }

    /// Preload images for movies (async, doesn't block UI)
    func preloadImages(for movies: [MovieDataModel]) {
        Task {
            for movie in movies {
                let fullURL = URLManager.image(movie.largePicture)
                _ = try? await images.getData(urlString: fullURL, realmCache: true)
            }
        }
    }

    func warmImageCache() {
        Task {
            let initialMovies = try? await fetchPaging(query: ["setFirstResult": "0"])
            preloadImages(for: initialMovies ?? [])
        }
    }

    func fetchMovieMetadata(imdbURL: String) async throws -> MovieMetadata {
        do {
            let imdbId: String
            if let range = imdbURL.range(of: "tt") {
                imdbId = String(imdbURL[range.lowerBound...])
            } else {
                imdbId = imdbURL
            }

            let data = try await rapidMovieDatabase.imdbTitle(imdbId: imdbId, realmCache: true)
            let json = try JSON(data: data)
            return MovieMetadata(
                title: json["Title"].stringValue,
                genre: json["Genre"].stringValue
            )
        } catch {
            throw handleError(error)
        }
    }

    private func persistMoviesToRealmCache(_ movies: [MovieDataModel]) async {
        await MainActor.run {
            for movie in movies {
                guard let encoded = encodeMovie(movie) else { continue }
                self.realmCache.save(encoded, for: movieCacheKey(movieId: movie.movieIdString))
            }
        }
    }

    private func movieCacheKey(movieId: String) -> String {
        "movies/by-id/\(movieId)"
    }

    private func encodeMovie(_ movie: MovieDataModel) -> Data? {
        let payload: [String: Any] = [
            "movieId": movie.movieIdString,
            "name": movie.name,
            "detail": movie.detail,
            "large_picture": movie.largePicture,
            "iMDB_url": movie.imdbUrl,
        ]
        return try? JSONSerialization.data(withJSONObject: payload, options: [])
    }
}

struct MovieMetadata {
    let title: String
    let genre: String
}

struct Movie {
    let movieId: Int
    let movieIdString: String
    let name: String
    let detail: String
    let largePicture: String
    let imdbUrl: String

    init(movieId: Int, movieIdString: String, name: String, detail: String, largePicture: String, imdbUrl: String) {
        self.movieId = movieId
        self.movieIdString = movieIdString
        self.name = name
        self.detail = detail
        self.largePicture = largePicture
        self.imdbUrl = imdbUrl
    }

    init?(json: JSON) {
        let idStr = json["movieId"].string ?? json["movieId"].int.map(String.init)
        guard let idStr,
              let id = Int(idStr),
              let name = json["name"].string else {
            return nil
        }

        let detail = json["detail"].string
            ?? json["description"].string
            ?? ""
        let picture = json["large_picture"].string
            ?? json["thumbnail_picture"].string
            ?? ""
        let imdb = json["iMDB_url"].string
            ?? json["imdbUrl"].string
            ?? ""

        self.movieId = id
        self.movieIdString = idStr
        self.name = name
        self.detail = detail
        self.largePicture = picture
        self.imdbUrl = imdb
    }
}

typealias MovieDataModel = Movie


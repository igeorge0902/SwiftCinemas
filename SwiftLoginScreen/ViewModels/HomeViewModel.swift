import Foundation

@MainActor
final class HomeViewModel {
    struct TrendingMovie {
        let movieId: Int
        let name: String
        let thumbnailPicture: String
        let largePicture: String
        let bookedTickets: Int
        let lastBookingTime: String?
        let descriptionText: String
    }

    struct State {
        enum Phase { case idle, loading, loaded, failed }
        var phase: Phase = .idle
        var trendingMovies: [TrendingMovie] = []
        var trendingErrorMessage: String?
        var isLoadingTrending: Bool {
            if case .loading = phase { return true }
            return false
        }
    }

    private let movies: MoviesDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(movies: MoviesDataManager, locations: LocationsDataManager) {
        self.movies = movies
        self.locations = locations
    }

    func warmImageCache() { movies.warmImageCache() }

    func selectMapFlow() {
        locations.isVenuesFromMapFlow = true
        locations.isMapFromVenueDetails = false
    }

    func beginTrendingLoad() {
        state.phase = .loading
        state.trendingErrorMessage = nil
        onStateChange?(state)
    }

    func loadTrending(days: Int? = nil) async {
        beginTrendingLoad()
        let started = Date()
        print("HomeVC.trending request start days=\(days.map(String.init) ?? "default") limit=5")
        do {
            let fetched = try await movies.fetchTrending(limit: 5, days: days)
            state.trendingMovies = fetched.map {
                TrendingMovie(movieId: $0.movieId, name: $0.name, thumbnailPicture: "",
                              largePicture: $0.largePicture, bookedTickets: 0, lastBookingTime: nil,
                              descriptionText: $0.detail.isEmpty ? "Trending now." : $0.detail)
            }
            state.phase = .loaded
            state.trendingErrorMessage = nil
            print("HomeVC.trending ok count=\(state.trendingMovies.count) ms=\(Int(Date().timeIntervalSince(started) * 1000))")
        } catch {
            state.phase = .failed
            state.trendingMovies.removeAll()
            state.trendingErrorMessage = "Could not load trending movies. Tap to retry."
            print("HomeVC.trending failed ms=\(Int(Date().timeIntervalSince(started) * 1000)) error=\(error)")
        }
        onStateChange?(state)
    }
}

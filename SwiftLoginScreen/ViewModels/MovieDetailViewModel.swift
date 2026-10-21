import Foundation

@MainActor
final class MovieDetailViewModel {
    struct State {
        var metadata: MovieMetadata?
        var isLoading = false
        var error: Error?
    }
    private let movies: MoviesDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(movies: MoviesDataManager) { self.movies = movies }
    var selectedMovie: MovieDataModel? { movies.selectedMovie }
    func select(_ movie: MovieDataModel) { movies.selectedMovie = movie }

    func load(imdbURL: String) async {
        state.isLoading = true
        state.error = nil
        do {
            state.metadata = try await movies.fetchMovieMetadata(imdbURL: imdbURL)
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            NSLog("MovieDetailVC RapidAPI: %@", error.localizedDescription)
        }
    }
}

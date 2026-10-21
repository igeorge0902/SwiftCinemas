import Foundation

@MainActor
final class MoviesViewModel {
    enum SearchAction {
        case none, delayedSearch, adminSearch, browseReload, adminReload
    }
    enum PagingRequest { case browse, search }
    struct State {
        enum RowChange { case movies, admin }
        var rowChange: RowChange = .movies
        var browse: [MovieDataModel] = []
        var search: [MovieDataModel] = []
        var adminRows: [AdminScreeningModel] = []
        var categories: [String] = []
        var section = 0
        var category: String?
        var searchString: String?
        var categoryChips: [String] = []
        var favorites: [Int: Bool] = [:]
        var ratings: [Int: String] = [:]
        var selectedPopoverMovieRow: Int?
        var isLoading = false
        var error: Error?
    }

    private let movies: MoviesDataManager
    private let admin: AdminDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?
    let fallbackCategories = ["All", "Action", "Drama", "Crime", "Romance", "Troll"]

    init(movies: MoviesDataManager, admin: AdminDataManager) {
        self.movies = movies
        self.admin = admin
    }

    func setCategory(_ category: String?) { state.category = category }
    func setSearchString(_ text: String?) { state.searchString = text }
    func clearBrowse() { state.browse.removeAll() }
    func clearSearchAndBrowse() {
        state.search.removeAll()
        state.browse.removeAll()
    }
    func clearAdmin() { state.adminRows.removeAll() }

    func searchTextChanged(_ text: String, isAdminUpdate: Bool) -> SearchAction {
        if text.substring(from: text.startIndex).count > 2 {
            clearSearchAndBrowse()
            if !isAdminUpdate { return .delayedSearch }
            clearAdmin()
            if state.section == 0 || state.section == 1 { return .adminSearch }
        }
        if text.substring(from: text.startIndex).count == 0 {
            clearSearchAndBrowse()
            return isAdminUpdate ? .adminReload : .browseReload
        }
        return .none
    }

    func selectCategoryChip(_ title: String) {
        state.category = title == "All" ? "nil" : title
        clearSearchAndBrowse()
    }

    func pagingRequests(for row: Int, isAdminUpdate: Bool) -> [PagingRequest] {
        var requests: [PagingRequest] = []
        var searchCount = state.search.count
        func appendExistingTriggers() {
            if state.browse.count > 10 || searchCount > 10 {
                if row == state.browse.count - 3 {
                    if !endOfFile { requests.append(.browse) }
                    if row == searchCount - 3, !endOfFile {
                        requests.append(.search)
                        // addData_ prepares its query by clearing search synchronously.
                        // The original second admin pass therefore sees count zero.
                        searchCount = 0
                    }
                }
            }
        }
        appendExistingTriggers()
        // Preserve the existing second trigger pass in admin-update mode.
        if isAdminUpdate { appendExistingTriggers() }
        return requests
    }

    func selectSection(_ section: Int) {
        state.section = section
        if section == 0 {
            state.category = nil
            clearSearchAndBrowse()
            state.categories.removeAll()
            clearAdmin()
        } else if section == 1 {
            state.categories = ["Action", "Drama", "Crime", "Romance", "Troll"]
            clearSearchAndBrowse()
            clearAdmin()
        }
    }

    func clearAdminContext() {
        admin.screeningsForAdminUpdate = []
        admin.selectedScreen = nil
    }

    func selectMovie(_ movie: MovieDataModel) { movies.selectedMovie = movie }
    func selectAdminScreen(at row: Int) {
        if !state.adminRows.isEmpty { admin.selectedScreen = state.adminRows[row] }
    }

    func selectedMovie(at row: Int) -> MovieDataModel? {
        if !state.browse.isEmpty { return state.browse[row] }
        if !state.search.isEmpty { return state.search[row] }
        return nil
    }

    // These queries are prepared synchronously before the controller's existing task boundary.
    func browseQuery(category: String) -> [String: String] {
        if category != "nil" {
            return ["category": category, "setFirstResult": String(state.browse.count)]
        }
        return ["setFirstResult": String(state.browse.count)]
    }

    func searchQuery(_ match: String, category: String) -> [String: String] {
        state.search.removeAll()
        var query = ["match": match, "setFirstResult": String(state.search.count)]
        if category != "nil" { query["category"] = category }
        return query
    }

    func loadBrowse(query: [String: String]) async {
        beginLoading()
        do {
            let fetched = try await movies.fetchPaging(query: query)
            state.browse.append(contentsOf: fetched)
            resolveCategories(from: state.browse)
            endOfFile = fetched.isEmpty
            finishLoading()
        } catch { fail(error, prefix: "addData: %@") }
    }

    func loadSearch(query: [String: String]) async {
        beginLoading()
        do {
            state.search = try await movies.search(query: query)
            shouldShowSearchResults = true
            resolveCategories(from: state.search)
            endOfFile = state.search.isEmpty
            finishLoading()
        } catch { fail(error, prefix: "addData_: %@") }
    }

    func loadAdmin(category: String? = nil, publishRows: Bool = true) async -> Bool {
        beginLoading()
        do {
            state.adminRows = try await admin.fetchScreenings(category: category)
            state.isLoading = false
            state.rowChange = .admin
            if publishRows { onStateChange?(state) }
            return true
        } catch {
            fail(error, prefix: category == nil ? "addLoadMoviesonVenue: %@" : "addLoadMoviesonVenue(category): %@")
            return false
        }
    }

    func searchAdmin(_ match: String) async {
        beginLoading()
        do {
            state.adminRows = try await admin.searchScreenings(match: match)
            state.isLoading = false
            state.rowChange = .admin
            onStateChange?(state)
        } catch { fail(error, prefix: "addLoadMoviesonVenue(search): %@") }
    }

    // No debounce cancellation or stale-result filtering: every admitted search still runs.
    func delayedSearch(_ text: String) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                continuation.resume()
            }
        }
        let query = searchQuery(text, category: state.category ?? "nil")
        await loadSearch(query: query)
    }

    func resolveCategories(from rows: [MovieDataModel]) {
        // The existing category extractor returns nil; retain its fallback behavior.
        let extracted = Set(rows.compactMap { _ -> String? in nil })
        if extracted.isEmpty {
            state.categoryChips = fallbackCategories
            NSLog("MoviesVC categories source=fallback count=%d", state.categoryChips.count)
        } else {
            state.categoryChips = ["All"] + extracted.sorted()
            NSLog("MoviesVC categories source=backend count=%d", state.categoryChips.count)
        }
    }

    func toggleFavorite(movieId: Int) {
        state.favorites[movieId] = !(state.favorites[movieId] ?? false)
    }

    func loadRatingsFixture() {
        guard let url = Bundle.main.url(forResource: "ratings-mock", withExtension: "json") else {
            state.ratings = [:]
            NSLog("MoviesVC ratings source=fallback count=0")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(RatingsPayload.self, from: data)
            state.ratings = Dictionary(uniqueKeysWithValues: payload.ratings.map { ($0.movieId, $0.rating) })
            NSLog("MoviesVC ratings source=fixture count=%d", state.ratings.count)
        } catch {
            state.ratings = [:]
            NSLog("MoviesVC ratings source=fallback error=%@", error.localizedDescription)
        }
    }

    private func beginLoading() {
        state.isLoading = true
        state.error = nil
    }
    private func finishLoading() {
        state.isLoading = false
        state.rowChange = .movies
        onStateChange?(state)
    }
    private func fail(_ error: Error, prefix: String) {
        state.isLoading = false
        state.error = error
        NSLog(prefix, error.localizedDescription)
    }

    private struct RatingsPayload: Codable { let ratings: [RatingItem] }
    private struct RatingItem: Codable {
        let movieId: Int
        let rating: String
    }
}

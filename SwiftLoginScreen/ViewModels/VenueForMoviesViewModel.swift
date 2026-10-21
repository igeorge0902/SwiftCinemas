import Foundation

@MainActor
final class VenueForMoviesViewModel {
    struct State {
        var rows: [VenueMovieSelection] = []
        var shouldShowSearchResults = false
        var isLoading = false
        var error: Error?
    }
    struct DisplayRow {
        let title: String
        let imagePath: String
        let categoryText: String
        let screeningDateText: String
    }
    private let venues: VenuesDataManager
    private let movies: MoviesDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(venues: VenuesDataManager, movies: MoviesDataManager, locations: LocationsDataManager) {
        self.venues = venues
        self.movies = movies
        self.locations = locations
    }
    var selectedLocationId: Int? { locations.selectedLocationId }
    func setSearchResultsVisible(_ visible: Bool) { state.shouldShowSearchResults = visible }
    func clearRows() { state.rows.removeAll() }

    func load(locationId: Int) async {
        state.isLoading = true
        state.error = nil
        do {
            state.rows = try await venues.fetchVenueMovieSelections(locationId: String(locationId))
            state.isLoading = false
            onStateChange?(state)
        } catch {
            state.isLoading = false
            state.error = error
            NSLog("VenueForMoviesVC addData: %@", error.localizedDescription)
        }
    }

    func select(at row: Int, locationId: Int) {
        let selection = state.rows[row]
        movies.selectedMovie = selection.movie
        venues.selectedVenue = Venue(venuesId: selection.venue.venuesId, name: selection.venue.name,
                                     address: selection.venue.address, venuesPicture: selection.venue.venuesPicture,
                                     screenId: selection.venue.screenId, locationId: locationId)
        locations.selectedLocationId = locationId
    }

    func displayRow(from selection: VenueMovieSelection) -> DisplayRow {
        let category = (selection.category?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? selection.category! : "N/A"
        let screeningDate = (selection.screeningDate?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? selection.screeningDate! : "TBA"
        return DisplayRow(title: selection.movie.name, imagePath: selection.movie.largePicture,
                          categoryText: "Category: \(category)", screeningDateText: "Date: \(screeningDate)")
    }
}

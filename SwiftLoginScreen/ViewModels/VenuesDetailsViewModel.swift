import Foundation

@MainActor
final class VenuesDetailsViewModel {
    struct Context {
        var selectVenuesPicture: String?
        var selectLargePicture: String?
        var selectVenueId: Int?
        var venueName: String?
        var selectAddress: String?
        var movieId: Int?
        var movieName: String?
        var movieDetails: String?
        var screenScreenId: String?
        var locationId: Int?
        var iMDB: String?
    }
    struct State {
        var context = Context()
        var isLoadingDates = false
        var isLoadingSeats = false
        var error: Error?
    }
    private let dates: DatesDataManager
    private let seats: SeatsDataManager
    private let movies: MoviesDataManager
    private let venues: VenuesDataManager
    private let locations: LocationsDataManager
    private(set) var state = State()
    var onStateChange: ((State) -> Void)?

    init(dates: DatesDataManager, seats: SeatsDataManager, movies: MoviesDataManager,
         venues: VenuesDataManager, locations: LocationsDataManager) {
        self.dates = dates
        self.seats = seats
        self.movies = movies
        self.venues = venues
        self.locations = locations
    }

    // Existing public controller inputs feed this single context before lifecycle resolution.
    func updateInput(_ update: (inout Context) -> Void) { update(&state.context) }
    var hasSelectedDate: Bool { dates.selectedScreeningDateId != nil }
    var hasDates: Bool { !dates.availableDates.isEmpty }
    var resolvedScreenId: String? {
        let id = state.context.screenScreenId ?? venues.selectedVenue?.screenId
        guard let id, !id.isEmpty else { return nil }
        return id
    }

    func resolveContext() {
        var context = state.context
        context.movieId = context.movieId ?? movies.selectedMovie?.movieId
        context.movieName = context.movieName ?? movies.selectedMovie?.name
        context.movieDetails = context.movieDetails ?? movies.selectedMovie?.detail
        context.selectLargePicture = context.selectLargePicture ?? movies.selectedMovie?.largePicture
        context.iMDB = context.iMDB ?? movies.selectedMovie?.imdbUrl
        context.selectVenueId = context.selectVenueId ?? venues.selectedVenue?.venuesId
        context.venueName = context.venueName ?? venues.selectedVenue?.name
        context.selectAddress = context.selectAddress ?? venues.selectedVenue?.address
        context.selectVenuesPicture = context.selectVenuesPicture ?? venues.selectedVenue?.venuesPicture
        context.screenScreenId = context.screenScreenId ?? venues.selectedVenue?.screenId
        context.locationId = context.locationId ?? venues.selectedVenue?.locationId ?? locations.selectedLocationId
        state.context = context
        if let id = context.movieId, let name = context.movieName, let details = context.movieDetails,
           let picture = context.selectLargePicture, let imdb = context.iMDB {
            movies.selectedMovie = Movie(movieId: id, movieIdString: String(id), name: name,
                                         detail: details, largePicture: picture, imdbUrl: imdb)
        }
        if let id = context.selectVenueId, let name = context.venueName, let address = context.selectAddress,
           let screen = context.screenScreenId, let location = context.locationId {
            venues.selectedVenue = Venue(venuesId: id, name: name, address: address,
                                         venuesPicture: context.selectVenuesPicture ?? "", screenId: screen,
                                         locationId: location)
        }
        onStateChange?(state)
    }

    func loadDates() async throws -> Bool {
        if state.isLoadingDates { return hasDates }
        state.isLoadingDates = true
        state.error = nil
        defer { state.isLoadingDates = false }
        do {
            let fetched = try await dates.fetchDates(locationId: state.context.locationId!, movieId: state.context.movieId!)
            return !fetched.isEmpty
        } catch {
            state.error = error
            throw error
        }
    }

    func loadSeats() async throws -> Bool {
        guard let selected = dates.selectedScreeningDateId, let id = Int(selected) else { return false }
        state.isLoadingSeats = true
        state.error = nil
        do {
            _ = try await seats.fetchSeats(screeningDateId: id)
            return true
        } catch {
            state.error = error
            throw error
        }
    }

    func finishSeatPresentation() { state.isLoadingSeats = false }
    func selectMap() {
        locations.selectedLocationId = state.context.locationId
        locations.selectedVenueId = state.context.selectVenueId
        locations.isMapFromVenueDetails = true
    }
    func leave() {
        dates.resetNavigationContext()
        locations.activeMapView = nil
    }
}
